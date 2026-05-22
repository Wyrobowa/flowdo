import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundsEnabledNotifier extends StateNotifier<bool> {
  SoundsEnabledNotifier() : super(true) {
    _load();
  }

  static const _key = 'sounds_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final soundsEnabledProvider =
    StateNotifierProvider<SoundsEnabledNotifier, bool>(
  (ref) => SoundsEnabledNotifier(),
);
