import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DefaultIntNotifier extends StateNotifier<int> {
  _DefaultIntNotifier(this._key, int fallback) : super(fallback) {
    _load(fallback);
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

final defaultFocusProvider =
    StateNotifierProvider<_DefaultIntNotifier, int>(
  (ref) => _DefaultIntNotifier('default_focus', 25),
);

final defaultBreakProvider =
    StateNotifierProvider<_DefaultIntNotifier, int>(
  (ref) => _DefaultIntNotifier('default_break', 5),
);
