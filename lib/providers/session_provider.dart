import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/defaults_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/sounds_provider.dart';
import '../providers/stats_provider.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';

enum SessionPhase { focus, breakTime, done }

class SessionState {
  final List<Task> tasks;
  final int currentIndex;
  final SessionPhase phase;
  final int secondsRemaining;
  final bool isRunning;
  final int cycleSize; // 0 = no looping; N = N tasks per cycle
  final String origin; // route to return to when session ends

  const SessionState({
    required this.tasks,
    required this.currentIndex,
    required this.phase,
    required this.secondsRemaining,
    required this.isRunning,
    this.cycleSize = 0,
    this.origin = '/',
  });

  Task? get currentTask =>
      currentIndex < tasks.length ? tasks[currentIndex] : null;

  int get totalSeconds {
    final task = currentTask;
    if (task == null) return 1;
    return phase == SessionPhase.focus
        ? task.focusSeconds
        : task.breakSeconds;
  }

  double get progress =>
      totalSeconds > 0 ? secondsRemaining / totalSeconds : 0;

  // Cycle-aware progress helpers
  int get currentCycle =>
      cycleSize > 0 ? currentIndex ~/ cycleSize + 1 : 1;
  int get totalCycles =>
      cycleSize > 0 ? tasks.length ~/ cycleSize : 1;
  int get indexInCycle =>
      cycleSize > 0 ? currentIndex % cycleSize : currentIndex;
  int get tasksPerCycle =>
      cycleSize > 0 ? cycleSize : tasks.length;

  SessionState copyWith({
    int? currentIndex,
    SessionPhase? phase,
    int? secondsRemaining,
    bool? isRunning,
  }) =>
      SessionState(
        tasks: tasks,
        currentIndex: currentIndex ?? this.currentIndex,
        phase: phase ?? this.phase,
        secondsRemaining: secondsRemaining ?? this.secondsRemaining,
        isRunning: isRunning ?? this.isRunning,
        cycleSize: cycleSize,
        origin: origin,
      );
}

class SessionNotifier extends StateNotifier<SessionState?> {
  SessionNotifier(this._ref) : super(null);

  final Ref _ref;
  Timer? _timer;

  /// [cycleSize] — how many tasks form one cycle. 0 means no looping.
  /// [origin] — the route to navigate back to when the session ends.
  void start(List<Task> tasks, {int cycleSize = 0, String origin = '/'}) {
    _timer?.cancel();
    if (tasks.isEmpty) return;
    final first = tasks.first;
    state = SessionState(
      tasks: tasks,
      currentIndex: 0,
      phase: SessionPhase.focus,
      secondsRemaining: first.focusSeconds,
      isRunning: true,
      cycleSize: cycleSize,
      origin: origin,
    );
    _startTicking();
  }

  void togglePause() {
    final s = state;
    if (s == null || s.phase == SessionPhase.done) return;
    if (s.isRunning) {
      _timer?.cancel();
      NotificationService.cancel('phase_end');
    } else {
      _startTicking();
    }
    state = s.copyWith(isRunning: !s.isRunning);
  }

  void skip() {
    final s = state;
    if (s == null || s.phase == SessionPhase.done) return;
    _timer?.cancel();
    NotificationService.cancel('phase_end');
    _advance(s);
  }

  void stop() {
    _timer?.cancel();
    NotificationService.cancelAll();
    state = null;
  }

  void _startTicking() {
    _timer?.cancel();
    final s = state;
    final startedAt = DateTime.now();
    final initialRemaining = s?.secondsRemaining ?? 0;

    // Schedule a notification for when the current phase ends
    if (s != null) {
      final dueAt = startedAt.add(Duration(seconds: initialRemaining));
      NotificationService.schedulePhaseEnd(s.currentTask, s.phase, dueAt);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      if (s == null || !s.isRunning) return;
      final elapsed = DateTime.now().difference(startedAt).inSeconds;
      final remaining = (initialRemaining - elapsed).clamp(0, initialRemaining);
      if (remaining <= 0) {
        _timer?.cancel();
        _playTransitionSound(s);
        _advance(s);
      } else {
        state = s.copyWith(secondsRemaining: remaining);
        if (remaining <= _ref.read(countdownSecondsProvider)) _sound(SoundService.tick);
      }
    });
  }

  void _playTransitionSound(SessionState s) {
    final isLastTask = s.currentIndex + 1 >= s.tasks.length;
    final focusNoBreak = s.phase == SessionPhase.focus &&
        (s.currentTask?.breakSeconds ?? 0) == 0;
    if (isLastTask && (s.phase == SessionPhase.breakTime || focusNoBreak)) {
      _sound(SoundService.sessionComplete);
    } else if (s.phase == SessionPhase.focus) {
      _sound(SoundService.focusEnd);
    } else {
      _sound(SoundService.breakEnd);
    }
  }

  void _advance(SessionState s) {
    NotificationService.cancel('phase_end');
    if (s.phase == SessionPhase.focus) {
      final breakSecs = s.currentTask?.breakSeconds ?? 0;
      _notify(
        '${s.currentTask?.title ?? "Task"} done!',
        breakSecs > 0 ? 'Time for a break.' : 'Moving to next task.',
      );
      if (breakSecs > 0) {
        state = s.copyWith(
          phase: SessionPhase.breakTime,
          secondsRemaining: breakSecs,
          isRunning: true,
        );
        _startTicking();
      } else {
        _nextTask(s);
      }
    } else {
      _notify('Break over!', 'Back to work!');
      _nextTask(s);
    }
  }

  void _nextTask(SessionState s) {
    final nextIndex = s.currentIndex + 1;
    if (nextIndex >= s.tasks.length) {
      state = s.copyWith(
        phase: SessionPhase.done,
        secondsRemaining: 0,
        isRunning: false,
      );
      _notify('Session complete!', 'All done. Great work!');
      _ref.read(statsProvider.notifier).recordSession(s);
    } else {
      final next = s.tasks[nextIndex];
      state = s.copyWith(
        currentIndex: nextIndex,
        phase: SessionPhase.focus,
        secondsRemaining: next.focusSeconds,
        isRunning: true,
      );
      _startTicking();
    }
  }

  void _notify(String title, String body) {
    if (_ref.read(notificationsEnabledProvider)) {
      NotificationService.show(title, body);
    }
  }

  void _sound(Future<void> Function() fn) {
    if (_ref.read(soundsEnabledProvider)) fn();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState?>(
  (ref) => SessionNotifier(ref),
);
