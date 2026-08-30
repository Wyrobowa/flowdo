import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/providers/defaults_provider.dart';
import 'package:flowdo/screens/settings_screen.dart';
import 'package:flowdo/screens/timer_screen.dart';
import 'package:flowdo/services/notification_service.dart';
import 'package:flowdo/theme.dart';
import 'package:flowdo/widgets/duration_picker.dart';
import 'package:flowdo/widgets/repeat_picker.dart';

import 'support/notification_stub.dart';

void main() {
  /// Puts [values] in storage and holds them the way `main` does, since the
  /// screen seeds itself in `initState` and cannot await a load. Called afresh
  /// in every test, so nothing carries over from the last one.
  Future<void> storedAs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await loadPreferences();
  }

  setUp(() async {
    await storedAs({});
    // Settings reaches NotificationService while building its exact-alarm row,
    // and starting a session schedules its phase end.
    stubNotificationPlugin();
    await NotificationService.init();
  });

  tearDown(clearNotificationStub);

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(theme: appTheme, home: const TimerScreen())),
    );
    await tester.pumpAndSettle();
  }

  /// Pumps [screen] against a container the caller keeps, so a second screen —
  /// or a second visit to the same one — sees what the first left behind.
  Future<void> pumpWith(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: appTheme, home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the sections stack compactly', (tester) async {
    await pumpScreen(tester);

    final focus = tester.getTopLeft(find.text('Focus for')).dy;
    final rest = tester.getTopLeft(find.text('Then break for')).dy;
    final repeat = tester.getTopLeft(find.text('Repeat')).dy;

    // A section is label 20 + gap 8 + picker 48 = 76, with 20 between them.
    expect(tester.getSize(find.text('Focus for')).height, 20);
    expect(tester.getSize(find.byType(DurationPicker).first).height, 48);
    expect(rest - focus, 96);
    expect(repeat - focus, 192);

    // Repeat is now a section like the two above it. The chips it replaces
    // wrapped to 290 x 106 at 390pt.
    expect(tester.getSize(find.byType(RepeatPicker)).height, 48);
  });

  testWidgets('the repeat tile opens in place, pushing the rest down by 60',
      (tester) async {
    await pumpScreen(tester);

    final startButtonBefore = tester.getTopLeft(find.byType(FilledButton)).dy;

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    // The tile became the wheel: one section, grown by the same 60 a duration
    // unit grows by, with no second row underneath it.
    expect(tester.getSize(find.byType(RepeatPicker)).height, 108);
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(FilledButton)).dy - startButtonBefore,
      60,
    );
  });

  testWidgets('opening a picker grows it in place, pushing the rest down by 60',
      (tester) async {
    await pumpScreen(tester);

    final repeatBefore = tester.getTopLeft(find.text('Repeat')).dy;
    final breakPickerBefore = tester.getTopLeft(find.byType(DurationPicker).last);

    await tester.tap(find.text('m').first);
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(DurationPicker).first).height, 108);
    expect(tester.getTopLeft(find.text('Repeat')).dy - repeatBefore, 60);
    expect(
      tester.getTopLeft(find.byType(DurationPicker).last).dy -
          breakPickerBefore.dy,
      60,
    );
  });

  group('the setup it opens on', () {
    testWidgets('is the one last started, still there after a restart',
        (tester) async {
      // No provider has been read in this process, so the only thing standing
      // in for the last run is what a restart leaves behind: storage.
      await storedAs({
        'default_focus_s': 25 * 60,
        'default_break_s': 5 * 60,
        'last_focus_s': 45 * 60,
        'last_break_s': 10 * 60,
        'last_cycles': 2,
      });

      await pumpScreen(tester);

      expect(find.text('45'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('45m focus'), findsOneWidget);
      expect(find.text('10m break'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
    });

    testWidgets('falls back to the Settings defaults before the first run',
        (tester) async {
      await storedAs({'default_focus_s': 45 * 60, 'default_break_s': 10 * 60});

      await pumpScreen(tester);

      expect(find.text('45m focus'), findsOneWidget);
      expect(find.text('10m break'), findsOneWidget);
      // Repeat has no Settings default to fall back to; one run is the floor,
      // and a single run has no pill of its own.
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('×'), findsOneWidget);
    });

    testWidgets('is written by starting, and is showing on the way back',
        (tester) async {
      await storedAs({'default_focus_s': 25 * 60, 'default_break_s': 5 * 60});
      final container = ProviderContainer();
      final router = GoRouter(
        initialLocation: '/timer',
        routes: [
          GoRoute(path: '/timer', builder: (_, _) => const TimerScreen()),
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

      // Three repeats: no default can supply that, so seeing it again on the
      // way back can only have come from the run.
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -72));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start timer'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/session');

      router.go('/timer');
      await tester.pumpAndSettle();

      expect(find.text('25m focus'), findsOneWidget);
      expect(find.text('5m break'), findsOneWidget);
      expect(find.text('×3'), findsOneWidget);

      // And in storage, so the next launch opens on it too.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('last_focus_s'), 25 * 60);
      expect(prefs.getInt('last_break_s'), 5 * 60);
      expect(prefs.getInt('last_cycles'), 3);

      container.dispose();
    });

    testWidgets('gives way to a default the Settings screen just changed',
        (tester) async {
      await storedAs({
        'default_focus_s': 25 * 60,
        'default_break_s': 5 * 60,
        'last_focus_s': 45 * 60,
        'last_break_s': 10 * 60,
        'last_cycles': 2,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Move the focus default off 25m, one notch down the wheel.
      await pumpWith(tester, container, const SettingsScreen());
      await tester.tap(find.text('25'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListWheelScrollView), const Offset(0, 72));
      await tester.pumpAndSettle();
      expect(find.text('24'), findsOneWidget);

      await pumpWith(tester, container, const TimerScreen());

      // The change was deliberate, so it outranks the remembered 45m.
      expect(find.text('24m focus'), findsOneWidget);
      // The break default was left alone, so its remembered value stands, and
      // nothing in Settings speaks for the cycle count at all.
      expect(find.text('10m break'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
    });
  });
}
