import 'package:flutter/material.dart';

extension AppTheme on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// Unselected chip / number circle background.
  Color get chipSurface =>
      _isDark ? const Color(0xFF361A06) : const Color(0xFFE8C485);

  /// Progress tracks and timer ring background.
  Color get trackSurface =>
      _isDark ? const Color(0xFF2A1505) : const Color(0xFFDFB870);

  /// Mode-select cards and bottom sheet surfaces.
  Color get cardSurface =>
      _isDark ? const Color(0xFF2A1505) : const Color(0xFFF0D09A);
}
