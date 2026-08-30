import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowdo/extensions.dart';

import 'support/contrast.dart';

void main() {
  group('the ink a filled control draws on its fill', () {
    test('clears 3:1 on any fill, not only the ones drawn today', () {
      // A sweep of the space a later fill could land in, rather than the two
      // phase colours the app happens to draw now.
      for (var hue = 0.0; hue < 360; hue += 5) {
        for (var saturation = 0.0; saturation <= 1; saturation += 0.1) {
          for (var value = 0.0; value <= 1; value += 0.05) {
            final fill = HSVColor.fromAHSV(1, hue, saturation, value).toColor();
            final ratio = contrastRatio(fill.onFill, fill);
            expect(
              ratio,
              greaterThanOrEqualTo(3.0),
              reason: 'the ink on $fill measures ${ratio.toStringAsFixed(2)}:1',
            );
          }
        }
      }
    });
  });
}
