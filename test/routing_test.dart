import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/providers/defaults_provider.dart';
import 'package:flowdo/providers/features_provider.dart';
import 'package:flowdo/screens/home_screen.dart';
import 'package:flowdo/screens/session_screen.dart';
import 'package:flowdo/screens/settings_screen.dart';
import 'package:flowdo/screens/timer_screen.dart';
import 'package:flowdo/services/notification_service.dart';
import 'package:flowdo/theme.dart';

import 'support/notification_stub.dart';

void main() {
  /// Puts the mode flags in storage and holds them the way `main` does. The
  /// route the app opens on is read the moment a screen builds, so a load that
  /// landed a frame later would answer for the wrong configuration.
  Future<void> modesStoredAs({required bool timer, required bool tasks}) async {
    SharedPreferences.setMockInitialValues({
      'feature_timer': timer,
      'feature_tasks': tasks,
    });
    await loadPreferences();
  }

  setUp(() async {
    await modesStoredAs(timer: true, tasks: true);
    // Settings reaches NotificationService while building its exact-alarm row.
    stubNotificationPlugin();
    await NotificationService.init();
  });

  tearDown(clearNotificationStub);

  /// The real screens under the routes they answer to, with a stand-in for the
  /// mode picker so that landing on it is unmistakable.
  ///
  /// `/splash` is missing on purpose: `SoundService.init` never completes under
  /// the test binding, so SplashScreen never gets as far as navigating. What it
  /// navigates to is `homeRouteProvider`, which the first group covers.
  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('mode picker')),
        ),
        GoRoute(path: '/timer', builder: (_, _) => const TimerScreen()),
        GoRoute(path: '/tasks', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/session', builder: (_, _) => const SessionScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: appTheme, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  group('the route the app calls home', () {
    Future<String> homeRoute() async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container.read(homeRouteProvider);
    }

    test('is the mode picker while both modes are enabled', () async {
      await modesStoredAs(timer: true, tasks: true);
      expect(await homeRoute(), '/');
    });

    test('is the timer when it is the only mode', () async {
      await modesStoredAs(timer: true, tasks: false);
      expect(await homeRoute(), '/timer');
    });

    test('is the task list when it is the only mode', () async {
      await modesStoredAs(timer: false, tasks: true);
      expect(await homeRoute(), '/tasks');
    });

    test('follows a mode turned back on, with no reload in between', () async {
      await modesStoredAs(timer: true, tasks: false);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(homeRouteProvider), '/timer');

      await container.read(featuresProvider.notifier).setTasks(true);

      expect(container.read(homeRouteProvider), '/');
    });
  });

  group('with one mode enabled', () {
    testWidgets('the timer is the top of the app, so it has no back arrow',
        (tester) async {
      await modesStoredAs(timer: true, tasks: false);
      await pumpAt(tester, '/timer');

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('the task list is the top of the app, so it has no back arrow',
        (tester) async {
      await modesStoredAs(timer: false, tasks: true);
      await pumpAt(tester, '/tasks');

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('Settings is one tap from the timer', (tester) async {
      await modesStoredAs(timer: true, tasks: false);
      final router = await pumpAt(tester, '/timer');

      await tapTooltip(tester, 'Settings');

      expect(router.state.uri.toString(), '/settings');
    });

    testWidgets('Settings is one tap from the task list', (tester) async {
      await modesStoredAs(timer: false, tasks: true);
      final router = await pumpAt(tester, '/tasks');

      await tapTooltip(tester, 'Settings');

      expect(router.state.uri.toString(), '/settings');
    });

    testWidgets('Back out of Settings returns to that mode, not the picker',
        (tester) async {
      await modesStoredAs(timer: false, tasks: true);
      final router = await pumpAt(tester, '/settings');

      await tapTooltip(tester, 'Back');

      expect(router.state.uri.toString(), '/tasks');
    });

    testWidgets('a session screen opened without a session lands on that mode',
        (tester) async {
      await modesStoredAs(timer: true, tasks: false);
      final router = await pumpAt(tester, '/session');

      expect(router.state.uri.toString(), '/timer');
    });
  });

  group('with both modes enabled', () {
    testWidgets('the timer goes back to the mode picker', (tester) async {
      final router = await pumpAt(tester, '/timer');

      await tapTooltip(tester, 'Back');

      expect(router.state.uri.toString(), '/');
      expect(find.text('mode picker'), findsOneWidget);
    });

    testWidgets('the task list goes back to the mode picker', (tester) async {
      final router = await pumpAt(tester, '/tasks');

      await tapTooltip(tester, 'Back');

      expect(router.state.uri.toString(), '/');
    });

    testWidgets('Settings is still one tap from the timer', (tester) async {
      final router = await pumpAt(tester, '/timer');

      await tapTooltip(tester, 'Settings');

      expect(router.state.uri.toString(), '/settings');
    });

    testWidgets('Settings is still one tap from the task list', (tester) async {
      final router = await pumpAt(tester, '/tasks');

      await tapTooltip(tester, 'Settings');

      expect(router.state.uri.toString(), '/settings');
    });

    testWidgets('Back out of Settings returns to the mode picker',
        (tester) async {
      final router = await pumpAt(tester, '/settings');

      await tapTooltip(tester, 'Back');

      expect(router.state.uri.toString(), '/');
    });
  });

  testWidgets('turning the second mode back on reaches the picker again, '
      'without a restart', (tester) async {
    await modesStoredAs(timer: true, tasks: false);
    final router = await pumpAt(tester, '/timer');

    await tapTooltip(tester, 'Settings');
    expect(router.state.uri.toString(), '/settings');

    // The timer's own switch is held on as the last mode standing, so this is
    // the one that moves.
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    await tapTooltip(tester, 'Back');

    expect(router.state.uri.toString(), '/');
    expect(find.text('mode picker'), findsOneWidget);
  });
}
