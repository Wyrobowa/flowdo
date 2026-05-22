import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeaturesState {
  final bool timer;
  final bool tasks;
  final bool groups;

  const FeaturesState({
    this.timer = true,
    this.tasks = true,
    this.groups = true,
  });

  int get enabledCount =>
      (timer ? 1 : 0) + (tasks ? 1 : 0) + (groups ? 1 : 0);

  FeaturesState copyWith({bool? timer, bool? tasks, bool? groups}) =>
      FeaturesState(
        timer: timer ?? this.timer,
        tasks: tasks ?? this.tasks,
        groups: groups ?? this.groups,
      );
}

class FeaturesNotifier extends StateNotifier<FeaturesState> {
  FeaturesNotifier() : super(const FeaturesState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = FeaturesState(
      timer: prefs.getBool('feature_timer') ?? true,
      tasks: prefs.getBool('feature_tasks') ?? true,
      groups: prefs.getBool('feature_groups') ?? true,
    );
  }

  Future<void> setTimer(bool val) => _update(
        state.copyWith(timer: val),
        key: 'feature_timer',
        val: val,
      );

  Future<void> setTasks(bool val) => _update(
        state.copyWith(tasks: val),
        key: 'feature_tasks',
        val: val,
      );

  Future<void> setGroups(bool val) => _update(
        state.copyWith(groups: val),
        key: 'feature_groups',
        val: val,
      );

  Future<void> _update(FeaturesState next, {required String key, required bool val}) async {
    // Always keep at least one mode enabled.
    if (next.enabledCount == 0) return;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }
}

final featuresProvider =
    StateNotifierProvider<FeaturesNotifier, FeaturesState>(
  (ref) => FeaturesNotifier(),
);
