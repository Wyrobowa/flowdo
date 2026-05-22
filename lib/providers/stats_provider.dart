import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_record.dart';
import 'session_provider.dart';

class StatsState {
  const StatsState({
    required this.totalSessions,
    required this.currentStreak,
    required this.lastSessionDay,
    required this.history,
  });

  final int totalSessions;
  final int currentStreak;
  final int lastSessionDay; // days since Unix epoch
  final List<SessionRecord> history;

  bool get hasStats => totalSessions > 0;
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier()
      : super(const StatsState(
          totalSessions: 0,
          currentStreak: 0,
          lastSessionDay: 0,
          history: [],
        )) {
    _load();
  }

  static const _kTotal = 'stats_total';
  static const _kStreak = 'stats_streak';
  static const _kLastDay = 'stats_last_day';
  static const _kHistory = 'session_history';

  static int get _today =>
      DateTime.now().difference(DateTime.utc(1970)).inDays;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final historyJson = p.getString(_kHistory);
    List<SessionRecord> history = [];
    if (historyJson != null) {
      final list = jsonDecode(historyJson) as List;
      history = list
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    state = StatsState(
      totalSessions: p.getInt(_kTotal) ?? 0,
      currentStreak: p.getInt(_kStreak) ?? 0,
      lastSessionDay: p.getInt(_kLastDay) ?? 0,
      history: history,
    );
  }

  Future<void> recordSession(SessionState session) async {
    final today = _today;
    final last = state.lastSessionDay;

    final streak = last == today
        ? state.currentStreak
        : last == today - 1
            ? state.currentStreak + 1
            : 1;
    final total = state.totalSessions + 1;

    final focusMinutes = session.tasks
            .map((t) => t.focusSeconds)
            .fold(0, (a, b) => a + b) ~/
        60;

    final record = SessionRecord(
      completedAt: DateTime.now(),
      focusMinutes: focusMinutes,
      taskCount: session.tasks.length,
      taskTitles: session.tasks.map((t) => t.title).toList(),
    );

    final newHistory = [record, ...state.history].take(50).toList();

    state = StatsState(
      totalSessions: total,
      currentStreak: streak,
      lastSessionDay: today,
      history: newHistory,
    );

    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTotal, total);
    await p.setInt(_kStreak, streak);
    await p.setInt(_kLastDay, today);
    await p.setString(
      _kHistory,
      jsonEncode(newHistory.map((r) => r.toJson()).toList()),
    );
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>(
  (ref) => StatsNotifier(),
);
