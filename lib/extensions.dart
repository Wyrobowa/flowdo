import 'package:flutter/material.dart';

extension AppTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get chipSurface =>
      _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

  Color get trackSurface =>
      _isDark ? const Color(0xFF222222) : const Color(0xFFE4E4E4);

  Color get cardSurface =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
}
