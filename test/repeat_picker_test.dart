import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdo/widgets/repeat_picker.dart';

Widget _host(int initial, ValueChanged<int> onChanged, {int max = 12}) =>
    MaterialApp(
      home: Scaffold(
        body: RepeatPicker(initial: initial, max: max, onChanged: onChanged),
      ),
    );

/// The single cell, whether it is showing the tile or the wheel.
Finder get _cell => find.descendant(
      of: find.byType(RepeatPicker),
      matching: find.byType(AnimatedSize),
    );

void main() {
  testWidgets('starts closed as one tile a third of the row wide',
      (tester) async {
    await tester.pumpWidget(_host(3, (_) {}));

    expect(find.text('3'), findsOneWidget);
    expect(find.text('×'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsNothing);
    expect(tester.getSize(find.byType(RepeatPicker)).height, 48);
    expect(tester.getSize(_cell).height, 48);

    // Laid out on the duration picker's grid — three columns, two 8px gaps —
    // so Repeat rhymes with one unit above it instead of stretching across.
    final row = tester.getSize(find.byType(RepeatPicker)).width;
    expect(tester.getSize(_cell).width, closeTo((row - 16) / 3, 0.01));
  });

  testWidgets('tapping the tile turns it into the wheel in place',
      (tester) async {
    await tester.pumpWidget(_host(3, (_) {}));

    final cellBefore = tester.getTopLeft(_cell);
    final widthBefore = tester.getSize(_cell).width;

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    // The wheel is the cell, not a second row underneath it: the whole picker
    // is the wheel's own 108, and the cell has not moved or changed width.
    expect(
      find.descendant(of: _cell, matching: find.byType(ListWheelScrollView)),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(RepeatPicker)).height, 108);
    expect(tester.getSize(_cell).height, 108);
    expect(tester.getTopLeft(_cell), cellBefore);
    expect(tester.getSize(_cell).width, widthBefore);
  });

  testWidgets('the glyph rides in the selection band', (tester) async {
    await tester.pumpWidget(_host(3, (_) {}));

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    // Still exactly one glyph, on the centred value only; its neighbours are
    // bare digits.
    expect(find.text('×'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      tester.getCenter(find.text('×')).dy,
      closeTo(tester.getCenter(_cell).dy, 18),
    );
  });

  testWidgets('the wheel stays open — there is nothing to collapse it',
      (tester) async {
    await tester.pumpWidget(_host(3, (_) {}));

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsOneWidget);

    // Tapping the open cell does nothing: Repeat has no neighbouring unit to
    // hand the open state to, so it simply stays scrollable.
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: _cell, matching: find.byType(ListWheelScrollView)),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(RepeatPicker)).height, 108);
  });

  testWidgets('scrolling the wheel reports the new count', (tester) async {
    int? reported;
    await tester.pumpWidget(_host(5, (v) => reported = v));

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, 72));
    await tester.pumpAndSettle();

    expect(reported, 3);
    // The band reads `3 ×`, the closed tile's content.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('×'), findsOneWidget);
  });

  testWidgets('the wheel runs 1..max, with 1 a normal value', (tester) async {
    int? reported;
    await tester.pumpWidget(_host(1, (v) => reported = v, max: 6));

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    // Nothing below 1 to scroll to.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, 144));
    await tester.pumpAndSettle();
    expect(reported, isNull);
    expect(find.text('1'), findsOneWidget);

    // And nothing above max.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(reported, 6);
  });
}
