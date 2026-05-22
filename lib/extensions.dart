import 'package:flutter/material.dart';

extension AppTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Unselected chip / number circle background.
  Color get chipSurface =>
      _isDark ? const Color(0xFF2E1E0A) : const Color(0xFFE4E0A5);

  /// Progress tracks and timer ring background.
  Color get trackSurface =>
      _isDark ? const Color(0xFF261608) : const Color(0xFFD8D490);

  /// Mode-select cards and bottom sheet surfaces.
  Color get cardSurface =>
      _isDark ? const Color(0xFF241808) : const Color(0xFFEDEAB8);
}
