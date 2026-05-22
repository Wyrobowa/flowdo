import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsState {
  const StatsState({
    required this.totalSessions,
    required this.currentStreak,
    required this.lastSessionDay,
  });

  final int totalSessions;
  final int currentStreak;
  final int lastSessionDay; // days since Unix epoch

  bool get hasStats => totalSessions > 0;
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier()
      : super(const StatsState(
          totalSessions: 0,
          currentStreak: 0,
          lastSessionDay: 0,
        )) {
    _load();
  }

  static const _kTotal = 'stats_total';
  static const _kStreak = 'stats_streak';
  static const _kLastDay = 'stats_last_day';

  static int get _today =>
      DateTime.now().difference(DateTime.utc(1970)).inDays;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = StatsState(
      totalSessions: p.getInt(_kTotal) ?? 0,
      currentStreak: p.getInt(_kStreak) ?? 0,
      lastSessionDay: p.getInt(_kLastDay) ?? 0,
    );
  }

  Future<void> recordSession() async {
    final today = _today;
    final last = state.lastSessionDay;

    final streak = last == today
        ? state.currentStreak
        : last == today - 1
            ? state.currentStreak + 1
            : 1;
    final total = state.totalSessions + 1;

    state = StatsState(
      totalSessions: total,
      currentStreak: streak,
      lastSessionDay: today,
    );

    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTotal, total);
    await p.setInt(_kStreak, streak);
    await p.setInt(_kLastDay, today);
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>(
  (ref) => StatsNotifier(),
);
