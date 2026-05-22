import 'package:flutter/material.dart';

extension AppTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Unselected chip / number circle background.
  Color get chipSurface =>
      _isDark ? const Color(0xFF2A1248) : const Color(0xFFDFC8FF);

  /// Progress tracks and timer ring background.
  Color get trackSurface =>
      _isDark ? const Color(0xFF200E3C) : const Color(0xFFD2B8FF);

  /// Mode-select cards and bottom sheet surfaces.
  Color get cardSurface =>
      _isDark ? const Color(0xFF1E0D36) : const Color(0xFFEAD8FF);
}
