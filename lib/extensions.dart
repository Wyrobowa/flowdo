import 'package:flutter/material.dart';

extension AppTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Warm chip / container background (e.g. unselected chips, number circles).
  Color get chipSurface =>
      _isDark ? const Color(0xFF2C2825) : const Color(0xFFF0EDE9);

  /// Slightly deeper surface used for progress tracks and the timer ring.
  Color get trackSurface =>
      _isDark ? const Color(0xFF252220) : const Color(0xFFEDE9E4);

  /// Card / sheet surface (e.g. mode-select cards).
  Color get cardSurface =>
      _isDark ? const Color(0xFF1E1B18) : Colors.white;
}
