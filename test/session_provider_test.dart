import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/models/task.dart';
import 'package:flowdo/providers/notifications_provider.dart';
import 'package:flowdo/providers/session_provider.dart';
import 'package:flowdo/providers/sounds_provider.dart';
import 'package:flowdo/providers/stats_provider.dart';
import 'package:flowdo/services/notification_service.dart';

import 'support/notification_stub.dart';

Task _task({String title = 'Task', int focus = 60, int brk = 30}) =>
    Task(title: title, focusSeconds: focus, breakSeconds: brk);

/// The engine schedules a real `Timer.periodic`, so every container must be
/// disposed. Tests that assert on a live session dispose explicitly.
Future<ProviderContainer> _warmContainer() async {
  final container = ProviderContainer();
  // Let both toggles load as disabled before the engine runs, so no test ever
  // reaches the audio or notification plugins through them.
  container.read(soundsEnabledProvider);
  container.read(notificationsEnabledProvider);
  container.read(statsProvider);
  // Constructing the notifier queues a post-frame restore. Run it here, while
  // this notifier is alive, so it can never fire against a disposed one from
  // an earlier test. With no saved session the restore is a no-op.
  container.read(sessionProvider.notifier);
  _pumpFrame();
  await pumpEventQueue();
  return container;
}


/// Fires the post-frame callback the notifier registers to restore a session.
void _pumpFrame() {
  SchedulerBinding.instance
    ..handleBeginFrame(Duration.zero)
    ..handleDrawFrame();
}

String _persistedSession({
  required List<Task> tasks,
  required int secondsRemaining,
  required DateTime savedAt,
  int currentIndex = 0,
  String phase = 'focus',
  bool isRunning = true,
  int cycleSize = 0,
  String origin = '/',
}) =>
    jsonEncode({
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'currentIndex': currentIndex,
      'phase': phase,
      'secondsRemaining': secondsRemaining,
      'isRunning': isRunning,
      'cycleSize': cycleSize,
      'origin': origin,
      'savedAt': savedAt.toIso8601String(),
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    stubNotificationPlugin();
    SharedPreferences.setMockInitialValues({
      'sounds_enabled': false,
      'notifications_enabled': false,
    });
    // Initialises the timezone database that scheduling depends on.
    await NotificationService.init();
  });

  tearDown(clearNotificationStub);

  group('start', () {
    test('opens on the first task in its focus phase', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);

      notifier.start([_task(focus: 120), _task(focus: 90)]);
      final state = container.read(sessionProvider)!;

      expect(state.currentIndex, 0);
      expect(state.phase, SessionPhase.focus);
      expect(state.secondsRemaining, 120);
      expect(state.isRunning, isTrue);
      expect(state.currentTask!.focusSeconds, 120);

      container.dispose();
    });

    test('ignores an empty task list', () async {
      final container = await _warmContainer();
      container.read(sessionProvider.notifier).start([]);

      expect(container.read(sessionProvider), isNull);
      container.dispose();
    });

    test('carries cycleSize and origin onto the state', () async {
      final container = await _warmContainer();
      container.read(sessionProvider.notifier).start(
        [_task(), _task(), _task(), _task()],
        cycleSize: 2,
        origin: '/tasks',
      );

      final state = container.read(sessionProvider)!;
      expect(state.cycleSize, 2);
      expect(state.origin, '/tasks');

      container.dispose();
    });
  });

  // skip() runs the same _advance path the timer takes when a phase expires,
  // so the phase machine is covered without depending on wall-clock time.
  group('phase advance', () {
    test('focus moves into the break when the task has one', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 60, brk: 45)]);

      notifier.skip();
      final state = container.read(sessionProvider)!;

      expect(state.phase, SessionPhase.breakTime);
      expect(state.secondsRemaining, 45);
      expect(state.currentIndex, 0);
      expect(state.isRunning, isTrue);

      container.dispose();
    });

    test('focus skips straight to the next task when there is no break',
        () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([
        _task(title: 'first', focus: 60, brk: 0),
        _task(title: 'second', focus: 90),
      ]);

      notifier.skip();
      final state = container.read(sessionProvider)!;

      expect(state.phase, SessionPhase.focus);
      expect(state.currentIndex, 1);
      expect(state.currentTask!.title, 'second');
      expect(state.secondsRemaining, 90);

      container.dispose();
    });

    test('a break rolls into the next task', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([
        _task(title: 'first', focus: 60, brk: 30),
        _task(title: 'second', focus: 90),
      ]);

      notifier.skip(); // into the break
      notifier.skip(); // into the next task

      final state = container.read(sessionProvider)!;
      expect(state.phase, SessionPhase.focus);
      expect(state.currentIndex, 1);
      expect(state.secondsRemaining, 90);

      container.dispose();
    });

    test('the last break completes the session', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 60, brk: 30)]);

      notifier.skip(); // into the break
      notifier.skip(); // past the last break

      final state = container.read(sessionProvider)!;
      expect(state.phase, SessionPhase.done);
      expect(state.secondsRemaining, 0);
      expect(state.isRunning, isFalse);

      container.dispose();
    });

    test('skip does nothing once the session is done', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 60, brk: 0)]);

      notifier.skip();
      expect(container.read(sessionProvider)!.phase, SessionPhase.done);

      notifier.skip();
      expect(container.read(sessionProvider)!.phase, SessionPhase.done);
      expect(container.read(sessionProvider)!.currentIndex, 0);

      container.dispose();
    });
  });

  group('pause and stop', () {
    test('togglePause flips isRunning both ways', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task()]);

      notifier.togglePause();
      expect(container.read(sessionProvider)!.isRunning, isFalse);

      notifier.togglePause();
      expect(container.read(sessionProvider)!.isRunning, isTrue);

      container.dispose();
    });

    test('togglePause is inert on a finished session', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 60, brk: 0)]);
      notifier.skip();

      notifier.togglePause();

      expect(container.read(sessionProvider)!.phase, SessionPhase.done);
      expect(container.read(sessionProvider)!.isRunning, isFalse);

      container.dispose();
    });

    test('stop clears the session and its saved copy', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task()]);
      await pumpEventQueue();

      notifier.stop();
      await pumpEventQueue();

      expect(container.read(sessionProvider), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('persisted_session'), isNull);

      container.dispose();
    });
  });

  group('stats', () {
    test('a completed session is recorded once', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([
        _task(title: 'first', focus: 60, brk: 0),
        _task(title: 'second', focus: 60, brk: 0),
      ]);

      notifier.skip();
      notifier.skip();

      final stats = container.read(statsProvider);
      expect(container.read(sessionProvider)!.phase, SessionPhase.done);
      expect(stats.totalSessions, 1);
      expect(stats.history.single.taskCount, 2);
      expect(stats.history.single.focusMinutes, 2);
      expect(stats.history.single.taskTitles, ['first', 'second']);

      container.dispose();
    });

    test('an abandoned session is not recorded', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(), _task()]);

      notifier.stop();

      expect(container.read(statsProvider).totalSessions, 0);
      container.dispose();
    });
  });

  group('notification side effects', () {
    test('starting a session schedules its phase end', () async {
      final container = await _warmContainer();
      notificationCalls.clear();

      container.read(sessionProvider.notifier).start([_task(focus: 300)]);
      await pumpEventQueue();

      expect(notificationCalls, contains('zonedSchedule'));
      container.dispose();
    });

    test('pausing cancels the pending phase end', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 300)]);
      await pumpEventQueue();
      notificationCalls.clear();

      notifier.togglePause();
      await pumpEventQueue();

      expect(notificationCalls, contains('cancel'));
      container.dispose();
    });

    test('stopping cancels every scheduled alert', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 300)]);
      await pumpEventQueue();
      notificationCalls.clear();

      notifier.stop();
      await pumpEventQueue();

      expect(notificationCalls, contains('cancelAll'));
      container.dispose();
    });

    test('an alert is shown when notifications are on', () async {
      SharedPreferences.setMockInitialValues({
        'sounds_enabled': false,
        'notifications_enabled': true,
      });
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 60, brk: 0)]);
      await pumpEventQueue();
      notificationCalls.clear();

      notifier.skip(); // completes the session
      await pumpEventQueue();

      expect(notificationCalls, contains('show'));
      container.dispose();
    });

    test('no alert is shown while notifications are switched off', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 60, brk: 0)]);
      await pumpEventQueue();
      notificationCalls.clear();

      notifier.skip(); // completes the session
      await pumpEventQueue();

      expect(container.read(sessionProvider)!.phase, SessionPhase.done);
      expect(notificationCalls, isNot(contains('show')));
      container.dispose();
    });
  });

  group('cycle helpers', () {
    SessionState stateAt(int index, {int cycleSize = 0, int tasks = 4}) =>
        SessionState(
          tasks: [for (var i = 0; i < tasks; i++) _task()],
          currentIndex: index,
          phase: SessionPhase.focus,
          secondsRemaining: 30,
          isRunning: true,
          cycleSize: cycleSize,
        );

    test('report position within a looping session', () {
      final state = stateAt(2, cycleSize: 2);
      expect(state.currentCycle, 2);
      expect(state.totalCycles, 2);
      expect(state.indexInCycle, 0);
      expect(state.tasksPerCycle, 2);
    });

    test('collapse to a single cycle when there is no looping', () {
      final state = stateAt(2);
      expect(state.currentCycle, 1);
      expect(state.totalCycles, 1);
      expect(state.indexInCycle, 2);
      expect(state.tasksPerCycle, 4);
    });

    test('progress reflects the remaining share of the phase', () {
      final state = SessionState(
        tasks: [_task(focus: 60, brk: 30)],
        currentIndex: 0,
        phase: SessionPhase.focus,
        secondsRemaining: 15,
        isRunning: true,
      );
      expect(state.totalSeconds, 60);
      expect(state.progress, 0.25);
    });
  });

  group('persistence', () {
    test('start saves the session', () async {
      final container = await _warmContainer();
      container.read(sessionProvider.notifier).start([_task(focus: 120)]);
      await pumpEventQueue();

      final prefs = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(prefs.getString('persisted_session')!) as Map<String, dynamic>;

      expect(saved['secondsRemaining'], 120);
      expect(saved['phase'], 'focus');
      expect(saved['isRunning'], isTrue);

      container.dispose();
    });

    test('completing a session removes the saved copy', () async {
      final container = await _warmContainer();
      final notifier = container.read(sessionProvider.notifier);
      notifier.start([_task(focus: 60, brk: 0)]);
      await pumpEventQueue();

      notifier.skip();
      await pumpEventQueue();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('persisted_session'), isNull);

      container.dispose();
    });
  });

  group('restore', () {
    test('a recent running session resumes with time deducted', () async {
      SharedPreferences.setMockInitialValues({
        'sounds_enabled': false,
        'notifications_enabled': false,
        'persisted_session': _persistedSession(
          tasks: [_task(title: 'saved', focus: 600, brk: 30)],
          secondsRemaining: 600,
          savedAt: DateTime.now().subtract(const Duration(seconds: 30)),
        ),
      });

      final container = await _warmContainer();

      final state = container.read(sessionProvider)!;
      expect(state.currentTask!.title, 'saved');
      expect(state.isRunning, isTrue);
      expect(state.secondsRemaining, inInclusiveRange(569, 570));

      container.dispose();
    });

    test('a session saved over 24h ago is discarded', () async {
      SharedPreferences.setMockInitialValues({
        'sounds_enabled': false,
        'notifications_enabled': false,
        'persisted_session': _persistedSession(
          tasks: [_task()],
          secondsRemaining: 600,
          savedAt: DateTime.now().subtract(const Duration(hours: 25)),
        ),
      });

      final container = await _warmContainer();

      expect(container.read(sessionProvider), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('persisted_session'), isNull);

      container.dispose();
    });

    test('a paused session is not resumed', () async {
      SharedPreferences.setMockInitialValues({
        'sounds_enabled': false,
        'notifications_enabled': false,
        'persisted_session': _persistedSession(
          tasks: [_task()],
          secondsRemaining: 600,
          savedAt: DateTime.now(),
          isRunning: false,
        ),
      });

      final container = await _warmContainer();

      expect(container.read(sessionProvider), isNull);
      container.dispose();
    });

    test('nothing is restored without a saved session', () async {
      final container = await _warmContainer();

      expect(container.read(sessionProvider), isNull);
      container.dispose();
    });
  });
}
