import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/models/task.dart';
import 'package:flowdo/providers/session_provider.dart';
import 'package:flowdo/screens/mode_select_screen.dart';
import 'package:flowdo/services/notification_service.dart';
import 'package:flowdo/theme.dart';

import 'support/notification_stub.dart';

/// Titles a screen reader would never confuse for the card's own copy.
List<Task> _tasks(int count) => List.generate(
      count,
      (i) => Task(
        title: 'Write chapter ${i + 1}',
        focusSeconds: 1500,
        breakSeconds: 300,
      ),
    );

const _cardLabel =
    'Tasks & breaks, Add tasks with custom focus time and breaks.';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Starting a session schedules its phase end.
    stubNotificationPlugin();
    await NotificationService.init();
  });

  tearDown(clearNotificationStub);

  /// Puts [tasks] in storage and pumps the picker under a router, since both
  /// of the card's targets are routes. The caller disposes the container: a
  /// session started from the card leaves a timer ticking behind it.
  Future<(ProviderContainer, GoRouter)> pumpPicker(
    WidgetTester tester, {
    List<Task> tasks = const [],
  }) async {
    SharedPreferences.setMockInitialValues({
      'tasks_v1': jsonEncode(tasks.map((t) => t.toJson()).toList()),
    });
    final container = ProviderContainer();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ModeSelectScreen()),
        GoRoute(
          path: '/tasks',
          builder: (_, _) => const Scaffold(body: Text('task list')),
        ),
        GoRoute(
          path: '/session',
          builder: (_, _) => const Scaffold(body: Text('session')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: appTheme, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return (container, router);
  }

  /// Every label in the semantics tree that speaks of tasks. The card body is
  /// merged into a single node, so a second entry here is a second control —
  /// which is what the play button has to be, rather than a node the card's
  /// exclusion swallows.
  List<String> taskLabels() => find.semantics
      .byPredicate(
        (SemanticsNode node) => node.label.toLowerCase().contains('task'),
      )
      .evaluate()
      .map((node) => node.label)
      .toList();

  group('the tasks card with a pending list', () {
    testWidgets('announces the body and the play control as two nodes',
        (tester) async {
      final handle = tester.ensureSemantics();
      final (container, _) = await pumpPicker(tester, tasks: _tasks(3));

      expect(taskLabels(), ['$_cardLabel, 3 tasks', 'Start 3 tasks']);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Start 3 tasks')),
        matchesSemantics(
          label: 'Start 3 tasks',
          isButton: true,
          hasTapAction: true,
        ),
      );

      // The 48dp target the tap target guidelines ask of it.
      expect(
        tester.getSize(find.bySemanticsLabel('Start 3 tasks')),
        const Size(48, 48),
      );

      container.dispose();
      handle.dispose();
    });

    testWidgets('starts the pending list without opening it', (tester) async {
      final (container, router) = await pumpPicker(tester, tasks: _tasks(3));

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/session');

      // One pass of the list, in the order it is stored, ending back on it.
      final session = container.read(sessionProvider)!;
      expect(
        session.tasks.map((t) => t.title),
        ['Write chapter 1', 'Write chapter 2', 'Write chapter 3'],
      );
      expect(session.cycleSize, 0);
      expect(session.origin, '/tasks');

      container.dispose();
    });

    testWidgets('leaves the done tasks out, the way the badge counts them',
        (tester) async {
      final tasks = _tasks(3);
      final (container, _) = await pumpPicker(
        tester,
        tasks: [tasks.first.copyWith(isDone: true), ...tasks.skip(1)],
      );

      expect(find.text('2 tasks'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();

      expect(
        container.read(sessionProvider)!.tasks.map((t) => t.title),
        ['Write chapter 2', 'Write chapter 3'],
      );

      container.dispose();
    });

    testWidgets('still opens the list when tapped away from the play control',
        (tester) async {
      final (container, router) = await pumpPicker(tester, tasks: _tasks(3));

      await tester.tap(find.text('Tasks & breaks'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/tasks');
      expect(container.read(sessionProvider), isNull);

      container.dispose();
    });
  });

  group('the tasks card with nothing pending', () {
    testWidgets('offers no play control, and stays a single node',
        (tester) async {
      final handle = tester.ensureSemantics();
      final (container, _) = await pumpPicker(tester);

      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(taskLabels(), [_cardLabel]);

      container.dispose();
      handle.dispose();
    });

    testWidgets('drops the play control once the list is all done',
        (tester) async {
      final (container, _) = await pumpPicker(
        tester,
        tasks: [for (final t in _tasks(2)) t.copyWith(isDone: true)],
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.text('2 tasks'), findsNothing);

      container.dispose();
    });

    testWidgets('still opens the list when tapped', (tester) async {
      final (container, router) = await pumpPicker(tester);

      await tester.tap(find.text('Tasks & breaks'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/tasks');

      container.dispose();
    });
  });
}
