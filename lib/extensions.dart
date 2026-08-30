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

  /// The hue a running session is drawn in. Focus keeps the app's amber;
  /// break takes a cooler teal so the phase reads without reading the label.
  ///
  /// Both break tones are chosen against two limits: they fill the 72pt Pause
  /// button under a white glyph (5.5:1 light, 3.7:1 dark, over the 3:1 asked
  /// of a non-text mark) and they are also drawn as small text on the
  /// scaffold (5.2:1 on #F8F8F8, 5.0:1 on #111111, over the 4.5:1 asked of
  /// text). One tone cannot do both on both backgrounds, hence the pair.
  Color get focusColor => Theme.of(this).colorScheme.primary;

  Color get breakColor =>
      _isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
}
