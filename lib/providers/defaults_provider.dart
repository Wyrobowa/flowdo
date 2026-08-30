import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferences read before the first frame. Screens that seed their state in
/// `initState` — Quick timer, the add-task sheet — cannot await a load, so
/// without this they build from the fallback and never see what is stored.
SharedPreferences? _prefs;

/// Call before `runApp`. Tests that go through `initState` call it too, after
/// `SharedPreferences.setMockInitialValues`.
Future<void> loadPreferences() async {
  _prefs = await SharedPreferences.getInstance();
}

class _DefaultIntNotifier extends StateNotifier<int> {
  _DefaultIntNotifier(String key, int fallback)
      : _key = key,
        super(_prefs?.getInt(key) ?? fallback) {
    if (_prefs == null) _load(fallback);
  }

  final String _key;

  Future<void> _load(int fallback) async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? fallback;
  }

  Future<void> set(int value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }
}

/// What Quick timer last ran, so it reopens on that setup. Null until it has
/// been run once, which is what makes the fallback to the Settings default
/// possible — and what clearing restores.
class _LastUsedIntNotifier extends StateNotifier<int?> {
  _LastUsedIntNotifier(String key)
      : _key = key,
        super(_prefs?.getInt(key)) {
    if (_prefs == null) _load();
  }

  final String _key;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key);
  }

  Future<void> set(int value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }

  /// Already cleared is a no-op, so one drag of a Settings picker reaches
  /// storage once rather than on every value it passes through.
  Future<void> clear() async {
    if (state == null) return;
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// Keys use _s suffix to store seconds (old keys stored minutes — separate namespace)
final defaultFocusProvider =
    StateNotifierProvider<_DefaultIntNotifier, int>(
  (ref) => _DefaultIntNotifier('default_focus_s', 25 * 60),
);

final defaultBreakProvider =
    StateNotifierProvider<_DefaultIntNotifier, int>(
  (ref) => _DefaultIntNotifier('default_break_s', 5 * 60),
);

final countdownSecondsProvider =
    StateNotifierProvider<_DefaultIntNotifier, int>(
  (ref) => _DefaultIntNotifier('countdown_s', 5),
);

// The Quick timer setup last started. Each is cleared by a deliberate change to
// the default it falls back to, so Settings wins until the next run.
final lastFocusProvider =
    StateNotifierProvider<_LastUsedIntNotifier, int?>(
  (ref) => _LastUsedIntNotifier('last_focus_s'),
);

final lastBreakProvider =
    StateNotifierProvider<_LastUsedIntNotifier, int?>(
  (ref) => _LastUsedIntNotifier('last_break_s'),
);

// Cycles have no Settings default to be overridden by, so nothing clears this.
final lastCyclesProvider =
    StateNotifierProvider<_LastUsedIntNotifier, int?>(
  (ref) => _LastUsedIntNotifier('last_cycles'),
);
