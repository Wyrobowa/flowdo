import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/models/task.dart';
import 'package:flowdo/providers/session_provider.dart';
import 'package:flowdo/screens/session_screen.dart';
import 'package:flowdo/services/notification_service.dart';
import 'package:flowdo/theme.dart';

import 'support/contrast.dart';
import 'support/notification_stub.dart';

/// Titles that never contain the word the progress assertions look for.
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
    ThemeData? theme,
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
        child: MaterialApp.router(theme: theme ?? appTheme, routerConfig: router),
      ),
    );
    await tester.pump();
    return (container, router);
  }

  /// Skip ends the focus phase, and a task with a break runs it next. The
  /// second pump outlasts the 150ms the phase colour takes to cross over.
  Future<void> skipToBreak(WidgetTester tester) async {
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Every label in the semantics tree that names the task position. The
  /// progress region excludes its children's semantics, so this has to stay a
  /// single entry: the visible copy must not be spoken a second time.
  List<String> positionLabels() => find.semantics
      .byPredicate((SemanticsNode node) => node.label.contains('Task '))
      .evaluate()
      .map((node) => node.label)
      .toList();

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

    testWidgets('leaves Stop on screen at a short screen height',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final (container, _) = await pumpSession(tester);

      // The timer area scrolls when it runs out of room; the controls sit
      // below it and stay put.
      expect(tester.getBottomLeft(find.text('Stop')).dy, lessThan(568));
      expect(tester.takeException(), isNull);

      container.dispose();
    });
  });

  group('the task progress region', () {
    testWidgets('names the position on screen in a single round',
        (tester) async {
      final handle = tester.ensureSemantics();
      final (container, _) = await pumpSession(tester, taskCount: 3);

      expect(find.text('Task 1 of 3'), findsOneWidget);
      expect(positionLabels(), ['Task 1 of 3']);

      container.dispose();
      handle.dispose();
    });

    testWidgets('names the round alongside the position across rounds',
        (tester) async {
      final handle = tester.ensureSemantics();
      final (container, _) =
          await pumpSession(tester, taskCount: 4, cycleSize: 2);

      expect(find.text('Round 1 of 2, Task 1 of 2'), findsOneWidget);
      expect(positionLabels(), ['Round 1 of 2, Task 1 of 2']);

      container.dispose();
      handle.dispose();
    });
  });

  group('the phase colour', () {
    /// Every colour the screen resolves from `phaseColor`, read back off the
    /// built tree rather than restated here, so a consumer left on the theme
    /// primary shows up as a mismatch inside the record.
    ({Color title, Color position, Color pauseFill}) phaseColors(
      WidgetTester tester, {
      required String phaseLabel,
    }) =>
        (
          title: tester.widget<Text>(find.text(phaseLabel)).style!.color!,
          position: tester.widget<Text>(find.text('Task 1 of 3')).style!.color!,
          pauseFill: (tester
                      .widget<AnimatedContainer>(find.ancestor(
                        of: find.byIcon(Icons.pause_rounded),
                        matching: find.byType(AnimatedContainer),
                      ))
                      .decoration!
                  as BoxDecoration)
              .color!,
        );

    for (final (name, theme) in [('light', appTheme), ('dark', darkTheme)]) {
      testWidgets('tells focus from break in the $name theme', (tester) async {
        final (container, _) = await pumpSession(tester, theme: theme);

        final focus = phaseColors(tester, phaseLabel: 'Focus');
        await skipToBreak(tester);
        final breakTime = phaseColors(tester, phaseLabel: 'Break');

        expect(breakTime.title, isNot(focus.title));
        expect(breakTime.position, isNot(focus.position));
        expect(breakTime.pauseFill, isNot(focus.pauseFill));

        container.dispose();
      });

      testWidgets('draws the whole break screen in one colour in the $name '
          'theme', (tester) async {
        final (container, _) = await pumpSession(tester, theme: theme);
        await skipToBreak(tester);

        final breakTime = phaseColors(tester, phaseLabel: 'Break');

        expect(breakTime.position, breakTime.title);
        expect(breakTime.pauseFill, breakTime.title);

        container.dispose();
      });
    }
  });

  group('the Pause glyph', () {
    /// The contrast between the glyph and the disc under it, with both colours
    /// read off the built tree and put through the WCAG formula, so the
    /// assertion measures what the screen draws rather than repeating the
    /// colours the screen was written to draw.
    double pauseContrast(WidgetTester tester) {
      final fill = (tester
                  .widget<AnimatedContainer>(find.ancestor(
                    of: find.byIcon(Icons.pause_rounded),
                    matching: find.byType(AnimatedContainer),
                  ))
                  .decoration!
              as BoxDecoration)
          .color!;
      final glyph =
          tester.widget<Icon>(find.byIcon(Icons.pause_rounded)).color!;
      return contrastRatio(glyph, fill);
    }

    for (final (name, theme) in [('light', appTheme), ('dark', darkTheme)]) {
      testWidgets('clears 3:1 against the fill of either phase in the $name '
          'theme', (tester) async {
        final (container, _) = await pumpSession(tester, theme: theme);

        expect(pauseContrast(tester), greaterThanOrEqualTo(3.0),
            reason: 'the focus fill in the $name theme');

        await skipToBreak(tester);

        expect(pauseContrast(tester), greaterThanOrEqualTo(3.0),
            reason: 'the break fill in the $name theme');

        container.dispose();
      });
    }
  });
}
