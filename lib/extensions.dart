import 'package:flutter/material.dart';

extension AppTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Unselected chip / number circle background.
  Color get chipSurface =>
      _isDark ? const Color(0xFF2C1A08) : const Color(0xFFE5D5B8);

  /// Progress tracks and timer ring background.
  Color get trackSurface =>
      _isDark ? const Color(0xFF241206) : const Color(0xFFDDCCA5);

  /// Mode-select cards and bottom sheet surfaces.
  Color get cardSurface =>
      _isDark ? const Color(0xFF211508) : const Color(0xFFEDE4D0);
}
