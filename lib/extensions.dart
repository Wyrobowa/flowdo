import 'package:flutter/material.dart';

extension DurationFormat on Duration {
  /// e.g. "25m", "1h 5m", "1m 30s", "90s"
  String get pretty {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    if (s > 0 && m > 0) return '${m}m ${s}s';
    if (s > 0) return '${s}s';
    return '${m}m';
  }
}

extension AppTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get chipSurface =>
      _isDark ? const Color(0xFF303030) : const Color(0xFFEEEEEE);

  Color get trackSurface =>
      _isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE4E4E4);

  Color get cardSurface =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
}
