import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/models/task.dart';
import 'package:flowdo/screens/home_screen.dart';
import 'package:flowdo/screens/mode_select_screen.dart';
import 'package:flowdo/providers/session_provider.dart';
import 'package:flowdo/screens/session_screen.dart';
import 'package:flowdo/services/notification_service.dart';
import 'package:flowdo/screens/settings_screen.dart';
import 'package:flowdo/screens/timer_screen.dart';
import 'package:flowdo/theme.dart';
import 'package:flowdo/widgets/duration_picker.dart';
import 'package:flowdo/widgets/repeat_picker.dart';
import 'package:flowdo/widgets/task_card.dart';

import 'support/notification_stub.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? appTheme,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Settings reaches NotificationService while building its exact-alarm row,
    // and starting a session schedules its phase end.
    stubNotificationPlugin();
    await NotificationService.init();
  });

  tearDown(clearNotificationStub);

  group('DurationPicker', () {
    testWidgets('unit tiles announce as selectable buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(DurationPicker(initial: const Duration(minutes: 25), onChanged: (_) {})),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('25 minutes')),
        matchesSemantics(
          label: '25 minutes',
          hint: 'Adjust',
          isButton: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );

      handle.dispose();
    });

    testWidgets('the open unit reports itself as selected and adjustable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(DurationPicker(initial: const Duration(minutes: 25), onChanged: (_) {})),
      );

      await tester.tap(find.bySemanticsLabel('25 minutes'));
      await tester.pumpAndSettle();

      // Still one node for the unit, but it is the wheel now: nothing to
      // collapse, and it has to be operable without a swipe gesture.
      expect(
        tester.getSemantics(find.bySemanticsLabel('25 minutes')),
        matchesSemantics(
          label: '25 minutes',
          hint: 'Swipe up or down to adjust',
          hasSelectedState: true,
          isSelected: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('the increase action moves the open wheel', (tester) async {
      final handle = tester.ensureSemantics();
      Duration? reported;
      await tester.pumpWidget(
        _host(DurationPicker(
          initial: const Duration(minutes: 25),
          onChanged: (d) => reported = d,
        )),
      );

      await tester.tap(find.bySemanticsLabel('25 minutes'));
      await tester.pumpAndSettle();

      tester.semantics.increase(find.semantics.byLabel('25 minutes'));
      await tester.pumpAndSettle();

      expect(reported, const Duration(minutes: 26));

      handle.dispose();
    });

    testWidgets('meets the tap target and labelling guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(DurationPicker(initial: const Duration(minutes: 25), onChanged: (_) {})),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      // The remaining tiles still have to clear the guidelines once one unit
      // has turned into the wheel.
      await tester.tap(find.bySemanticsLabel('25 minutes'));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('survives a large text scale in both states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: DurationPicker(
                  initial: const Duration(minutes: 25),
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.text('m'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('RepeatPicker', () {
    testWidgets('the closed tile announces its count as a button',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(RepeatPicker(initial: 3, max: 12, onChanged: (_) {})),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Repeat 3 times')),
        matchesSemantics(
          label: 'Repeat 3 times',
          hint: 'Adjust',
          isButton: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );

      handle.dispose();
    });

    testWidgets('a count of one is spoken as once, not "1 times"',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(RepeatPicker(initial: 1, max: 12, onChanged: (_) {})),
      );

      expect(find.bySemanticsLabel('Repeat once'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the open wheel reports itself as selected and adjustable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(RepeatPicker(initial: 3, max: 12, onChanged: (_) {})),
      );

      await tester.tap(find.bySemanticsLabel('Repeat 3 times'));
      await tester.pumpAndSettle();

      // The cell is the wheel now: no tap action, because there is nothing to
      // collapse, and it has to be operable without a swipe gesture. No
      // excludeSemantics either, or the wheel's values would be swallowed.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Repeat 3 times')),
        matchesSemantics(
          label: 'Repeat 3 times',
          hint: 'Swipe up or down to adjust',
          hasSelectedState: true,
          isSelected: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('the increase action moves the open wheel', (tester) async {
      final handle = tester.ensureSemantics();
      int? reported;
      await tester.pumpWidget(
        _host(RepeatPicker(initial: 3, max: 12, onChanged: (v) => reported = v)),
      );

      await tester.tap(find.bySemanticsLabel('Repeat 3 times'));
      await tester.pumpAndSettle();

      tester.semantics.increase(find.semantics.byLabel('Repeat 3 times'));
      await tester.pumpAndSettle();

      expect(reported, 4);

      handle.dispose();
    });

    testWidgets('meets the tap target and labelling guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(RepeatPicker(initial: 3, max: 12, onChanged: (_) {})),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.tap(find.bySemanticsLabel('Repeat 3 times'));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('survives a large text scale in both states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: RepeatPicker(initial: 3, max: 12, onChanged: (_) {}),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('screens meet the tap target and labelling guidelines', () {
    Future<void> check(WidgetTester tester, Widget screen) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(theme: appTheme, home: screen)),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    }

    testWidgets('mode select', (tester) async {
      await check(tester, const ModeSelectScreen());
    });

    testWidgets('mode select, with a pending list on the tasks card',
        (tester) async {
      // The card only offers its play control when there is something to run.
      SharedPreferences.setMockInitialValues({
        'tasks_v1': jsonEncode([
          Task(title: 'Write the report', focusSeconds: 1500, breakSeconds: 300)
              .toJson(),
        ]),
      });
      await check(tester, const ModeSelectScreen());
    });

    testWidgets('quick timer', (tester) async {
      await check(tester, const TimerScreen());
    });

    testWidgets('settings', (tester) async {
      await check(tester, const SettingsScreen());
    });

    testWidgets('tasks, with a task list and the repeat picker showing',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'tasks_v1': jsonEncode([
          Task(title: 'Write the report', focusSeconds: 1500, breakSeconds: 300)
              .toJson(),
        ]),
      });
      await check(tester, const HomeScreen());
    });

    testWidgets('a running session', (tester) async {
      final handle = tester.ensureSemantics();
      final container = ProviderContainer();
      container.read(sessionProvider.notifier).start([
        Task(title: 'Write the report', focusSeconds: 1500, breakSeconds: 300),
      ]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SessionScreen()),
        ),
      );
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      // The digits would otherwise be read out character by character.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Focus timer')).value,
        '25 minutes remaining',
      );

      container.read(sessionProvider.notifier).togglePause();
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Focus timer')).value,
        '25 minutes remaining, paused',
      );

      container.dispose();
      handle.dispose();
    });

    testWidgets('task card', (tester) async {
      await check(
        tester,
        Scaffold(
          body: ListView(
            children: [
              TaskCard(
                task: Task(
                  title: 'Write the report',
                  focusSeconds: 1500,
                  breakSeconds: 300,
                  notes: 'Second draft',
                ),
                index: 0,
              ),
            ],
          ),
        ),
      );
    });
  });
}
