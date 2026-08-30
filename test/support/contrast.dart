import 'dart:ui';

/// The WCAG contrast ratio between two opaque colours, computed from the
/// colours themselves so a test can measure what a screen renders instead of
/// restating the figures the code was written against.
double contrastRatio(Color a, Color b) {
  final one = a.computeLuminance();
  final other = b.computeLuminance();
  final lighter = one > other ? one : other;
  final darker = one > other ? other : one;
  return (lighter + 0.05) / (darker + 0.05);
}
