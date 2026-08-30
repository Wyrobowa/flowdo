import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/models/task.dart';
import 'package:flowdo/providers/session_provider.dart';
import 'package:flowdo/screens/session_screen.dart';
import 'package:flowdo/services/notification_service.dart';
import 'package:flowdo/theme.dart';

import 'support/notification_stub.dart';

List<Task> _tasks(int count) => List.generate(
      count,
      (i) => Task(
        title: 'Write chapter ${i + 1}',
        focusSeconds: 1500,
        breakSeconds: 300,
      ),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Starting a session schedules its phase end.
    stubNotificationPlugin();
    await NotificationService.init();
  });

  tearDown(clearNotificationStub);

  /// Runs the screen under a router, because Stop navigates to the route the
  /// session came from. A [taskCount] of 0 opens the screen with no session
  /// running. The caller disposes the container to stop the engine.
  Future<(ProviderContainer, GoRouter)> pumpSession(
    WidgetTester tester, {
    int taskCount = 3,
    int cycleSize = 0,
    String origin = '/',
  }) async {
    final container = ProviderContainer();
    if (taskCount > 0) {
      container.read(sessionProvider.notifier).start(
            _tasks(taskCount),
            cycleSize: cycleSize,
            origin: origin,
          );
    }

    final router = GoRouter(
      initialLocation: '/session',
      routes: [
        GoRoute(path: '/session', builder: (_, _) => const SessionScreen()),
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('mode'))),
        GoRoute(path: '/timer', builder: (_, _) => const Scaffold(body: Text('quick timer'))),
        GoRoute(path: '/tasks', builder: (_, _) => const Scaffold(body: Text('tasks'))),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: appTheme, routerConfig: router),
      ),
    );
    await tester.pump();
    return (container, router);
  }

  group('ending a running session', () {
    testWidgets('is offered by Stop alone, with nothing in the app bar',
        (tester) async {
      final (container, _) = await pumpSession(tester);

      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('End session'), findsNothing);
      expect(tester.widget<AppBar>(find.byType(AppBar)).actions, isNull);

      container.dispose();
    });

    testWidgets('takes a Quick timer session back to /timer', (tester) async {
      final (container, router) = await pumpSession(tester, origin: '/timer');

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/timer');
      expect(container.read(sessionProvider), isNull);

      container.dispose();
    });

    testWidgets('takes a Tasks session back to /tasks', (tester) async {
      final (container, router) = await pumpSession(tester, origin: '/tasks');

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/tasks');

      container.dispose();
    });

    testWidgets('still sends a screen opened without a session home',
        (tester) async {
      final (container, router) = await pumpSession(tester, taskCount: 0);
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/');

      container.dispose();
    });
  });
}
