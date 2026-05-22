import 'package:flutter/material.dart';

extension AppTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Unselected chip / number circle background.
  Color get chipSurface =>
      _isDark ? const Color(0xFF2C484C) : const Color(0xFFE8CCBC);

  /// Progress tracks and timer ring background.
  Color get trackSurface =>
      _isDark ? const Color(0xFF223A3D) : const Color(0xFFDFBFAA);

  /// Mode-select cards and bottom sheet surfaces.
  Color get cardSurface =>
      _isDark ? const Color(0xFF243C3F) : const Color(0xFFF0D9CC);
}
