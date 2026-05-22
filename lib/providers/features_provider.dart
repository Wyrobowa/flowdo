import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeaturesState {
  final bool timer;
  final bool tasks;

  const FeaturesState({this.timer = true, this.tasks = true});

  int get enabledCount => (timer ? 1 : 0) + (tasks ? 1 : 0);

  FeaturesState copyWith({bool? timer, bool? tasks}) =>
      FeaturesState(timer: timer ?? this.timer, tasks: tasks ?? this.tasks);
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
    );
  }

  Future<void> setTimer(bool val) => _update(state.copyWith(timer: val), 'feature_timer', val);
  Future<void> setTasks(bool val) => _update(state.copyWith(tasks: val), 'feature_tasks', val);

  Future<void> _update(FeaturesState next, String key, bool val) async {
    if (next.enabledCount == 0) return;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }
}

final featuresProvider = StateNotifierProvider<FeaturesNotifier, FeaturesState>(
  (ref) => FeaturesNotifier(),
);
