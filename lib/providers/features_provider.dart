import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'defaults_provider.dart';

class FeaturesState {
  final bool timer;
  final bool tasks;

  const FeaturesState({this.timer = true, this.tasks = true});

  int get enabledCount => (timer ? 1 : 0) + (tasks ? 1 : 0);

  FeaturesState copyWith({bool? timer, bool? tasks}) =>
      FeaturesState(timer: timer ?? this.timer, tasks: tasks ?? this.tasks);
}

class FeaturesNotifier extends StateNotifier<FeaturesState> {
  // Seeded before the first frame where it can be: the route the app opens on
  // follows from this, so a load that lands later would show the mode picker
  // to someone who turned a mode off.
  FeaturesNotifier() : super(_stored(preloadedPreferences)) {
    if (preloadedPreferences == null) _load();
  }

  static FeaturesState _stored(SharedPreferences? prefs) => FeaturesState(
        timer: prefs?.getBool('feature_timer') ?? true,
        tasks: prefs?.getBool('feature_tasks') ?? true,
      );

  Future<void> _load() async {
    state = _stored(await SharedPreferences.getInstance());
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

/// Where a screen goes when it has nowhere of its own to go back to. With both
/// modes on that is the mode picker; with one it is that mode's own screen,
/// which is the top of the app because there is nothing left to pick between.
final homeRouteProvider = Provider<String>((ref) {
  final features = ref.watch(featuresProvider);
  if (features.enabledCount > 1) return '/';
  return features.timer ? '/timer' : '/tasks';
});
