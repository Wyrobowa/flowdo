import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/notifications_provider.dart';
import '../services/notification_service.dart';

enum SessionPhase { focus, breakTime, done }

class SessionState {
  final List<Task> tasks;
  final int currentIndex;
  final SessionPhase phase;
  final int secondsRemaining;
  final bool isRunning;

  const SessionState({
    required this.tasks,
    required this.currentIndex,
    required this.phase,
    required this.secondsRemaining,
    required this.isRunning,
  });

  Task? get currentTask =>
      currentIndex < tasks.length ? tasks[currentIndex] : null;

  int get totalSeconds {
    final task = currentTask;
    if (task == null) return 1;
    return phase == SessionPhase.focus
        ? task.focusMinutes * 60
        : task.breakMinutes * 60;
  }

  double get progress =>
      totalSeconds > 0 ? secondsRemaining / totalSeconds : 0;

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
      );
}

class SessionNotifier extends StateNotifier<SessionState?> {
  SessionNotifier(this._ref) : super(null);

  final Ref _ref;
  Timer? _timer;

  void start(List<Task> tasks) {
    _timer?.cancel();
    if (tasks.isEmpty) return;
    final first = tasks.first;
    state = SessionState(
      tasks: tasks,
      currentIndex: 0,
      phase: SessionPhase.focus,
      secondsRemaining: first.focusMinutes * 60,
      isRunning: true,
    );
    _startTicking();
  }

  void togglePause() {
    final s = state;
    if (s == null || s.phase == SessionPhase.done) return;
    if (s.isRunning) {
      _timer?.cancel();
    } else {
      _startTicking();
    }
    state = s.copyWith(isRunning: !s.isRunning);
  }

  void skip() {
    final s = state;
    if (s == null || s.phase == SessionPhase.done) return;
    _timer?.cancel();
    _advance(s);
  }

  void stop() {
    _timer?.cancel();
    NotificationService.cancelAll();
    state = null;
  }

  void _startTicking() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      if (s == null || !s.isRunning) return;
      if (s.secondsRemaining <= 1) {
        _timer?.cancel();
        _advance(s);
      } else {
        state = s.copyWith(secondsRemaining: s.secondsRemaining - 1);
      }
    });
  }

  void _advance(SessionState s) {
    if (s.phase == SessionPhase.focus) {
      final breakSecs = (s.currentTask?.breakMinutes ?? 0) * 60;
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
      _notify(
        'Session complete!',
        'All ${s.tasks.length} tasks done. Great work!',
      );
    } else {
      final next = s.tasks[nextIndex];
      state = s.copyWith(
        currentIndex: nextIndex,
        phase: SessionPhase.focus,
        secondsRemaining: next.focusMinutes * 60,
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
