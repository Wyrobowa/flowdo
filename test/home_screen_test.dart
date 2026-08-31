import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/models/task.dart';
import 'package:flowdo/providers/session_provider.dart';
import 'package:flowdo/screens/home_screen.dart';
import 'package:flowdo/services/notification_service.dart';
import 'package:flowdo/theme.dart';

import 'support/notification_stub.dart';

List<Task> _tasks(int count, {int focusSeconds = 1500, int breakSeconds = 300}) =>
    List.generate(
      count,
      (i) => Task(
        title: 'Write chapter ${i + 1}',
        focusSeconds: focusSeconds,
        breakSeconds: breakSeconds,
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

  /// Puts [tasks] in storage and pumps the list under a router, since Start
  /// navigates. The caller disposes the container: a started session leaves a
  /// timer ticking behind it.
  Future<(ProviderContainer, GoRouter)> pumpTasks(
    WidgetTester tester,
    List<Task> tasks,
  ) async {
    SharedPreferences.setMockInitialValues({
      'tasks_v1': jsonEncode(tasks.map((t) => t.toJson()).toList()),
    });
    final container = ProviderContainer();

    final router = GoRouter(
      initialLocation: '/tasks',
      routes: [
        GoRoute(path: '/tasks', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('mode picker')),
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

  /// Moves the repeat picker to [count] the way a finger does: open the tile
  /// by its glyph, then scroll the wheel up by a row per step.
  Future<void> repeat(WidgetTester tester, int count) async {
    await tester.tap(find.text('×'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(ListWheelScrollView),
      Offset(0, -36.0 * (count - 1)),
    );
    await tester.pumpAndSettle();
  }

  group('the Start bar label', () {
    testWidgets('states the pending count and what the session will take',
        (tester) async {
      // Three tasks of 25m focus and a 5m break each: an hour and a half.
      final (container, _) = await pumpTasks(tester, _tasks(3));

      expect(find.text('Start session · 3 tasks · 1h 30m'), findsOneWidget);

      container.dispose();
    });

    testWidgets('counts a single task in the singular, seconds and all',
        (tester) async {
      final (container, _) = await pumpTasks(
        tester,
        _tasks(1, focusSeconds: 90, breakSeconds: 0),
      );

      expect(find.text('Start session · 1 task · 1m 30s'), findsOneWidget);

      container.dispose();
    });

    testWidgets('leaves the tasks already done out of both figures',
        (tester) async {
      final tasks = _tasks(3);
      final (container, _) = await pumpTasks(
        tester,
        [tasks.first.copyWith(isDone: true), ...tasks.skip(1)],
      );

      expect(find.text('Start session · 2 tasks · 1h'), findsOneWidget);

      container.dispose();
    });

    testWidgets('multiplies the total by the repeat count', (tester) async {
      final (container, _) = await pumpTasks(tester, _tasks(3));

      await repeat(tester, 2);

      // The count is what one pass runs; the total is what the button
      // commits to.
      expect(find.text('Start session · 3 tasks · 3h'), findsOneWidget);

      container.dispose();
    });

    testWidgets('stays short at the longest session the picker can ask for',
        (tester) async {
      final (container, _) = await pumpTasks(
        tester,
        _tasks(5, focusSeconds: 3300, breakSeconds: 300),
      );

      await repeat(tester, 6);

      // Six passes of five hours, and the minutes drop off a round total.
      expect(find.text('Start session · 5 tasks · 30h'), findsOneWidget);

      container.dispose();
    });
  });

  group('starting from the Start bar', () {
    testWidgets('runs the pending list once at a repeat of one',
        (tester) async {
      final (container, router) = await pumpTasks(tester, _tasks(3));

      await tester.tap(find.text('Start session · 3 tasks · 1h 30m'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/session');

      // What the mode card's play control starts, to the letter.
      final session = container.read(sessionProvider)!;
      expect(
        session.tasks.map((t) => t.title),
        ['Write chapter 1', 'Write chapter 2', 'Write chapter 3'],
      );
      expect(session.cycleSize, 0);
      expect(session.origin, '/tasks');

      container.dispose();
    });

    testWidgets('repeats the whole list when asked for more than one pass',
        (tester) async {
      final (container, _) = await pumpTasks(tester, _tasks(2));

      await repeat(tester, 2);
      await tester.tap(find.text('Start session · 2 tasks · 2h'));
      await tester.pumpAndSettle();

      final session = container.read(sessionProvider)!;
      expect(session.tasks.length, 4);
      expect(session.cycleSize, 2);

      container.dispose();
    });
  });
}
