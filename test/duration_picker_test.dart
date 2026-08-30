import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdo/widgets/duration_picker.dart';

Widget _host(Duration initial, ValueChanged<Duration> onChanged) => MaterialApp(
      home: Scaffold(
        body: DurationPicker(initial: initial, onChanged: onChanged),
      ),
    );

/// The cell holding [unit], whether it is showing a tile or the wheel: each of
/// the three sits in its own AnimatedSize.
Finder _cell(String unit) =>
    find.ancestor(of: find.text(unit), matching: find.byType(AnimatedSize));

void main() {
  testWidgets('starts closed with one tile per unit', (tester) async {
    await tester.pumpWidget(_host(const Duration(minutes: 25), (_) {}));

    expect(find.text('h'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
    expect(find.text('s'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsNothing);
    expect(tester.getSize(find.byType(DurationPicker)).height, 48);
  });

  testWidgets('tapping a unit turns that cell into the wheel in place',
      (tester) async {
    await tester.pumpWidget(_host(const Duration(minutes: 25), (_) {}));

    final hoursBefore = tester.getTopLeft(_cell('h'));
    final secondsBefore = tester.getTopLeft(_cell('s'));
    final minutesTop = tester.getTopLeft(_cell('m'));

    await tester.tap(find.text('m'));
    await tester.pumpAndSettle();

    // The wheel is the minutes cell, not a second row underneath it: the whole
    // picker is the wheel's own 108, and the cell's top edge has not moved.
    expect(
      find.descendant(
        of: _cell('m'),
        matching: find.byType(ListWheelScrollView),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(DurationPicker)).height, 108);
    expect(tester.getSize(_cell('m')).height, 108);
    expect(tester.getTopLeft(_cell('m')), minutesTop);

    // The neighbours keep their height and their exact offsets.
    expect(tester.getTopLeft(_cell('h')), hoursBefore);
    expect(tester.getTopLeft(_cell('s')), secondsBefore);
    expect(tester.getSize(_cell('h')).height, 48);
    expect(tester.getSize(_cell('s')).height, 48);
  });

  testWidgets('the unit glyph rides in the selection band', (tester) async {
    await tester.pumpWidget(_host(const Duration(minutes: 25), (_) {}));

    await tester.tap(find.text('m'));
    await tester.pumpAndSettle();

    // Still exactly one 'm', now next to the centred value, and only the
    // centred item carries it.
    expect(find.text('m'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(
      find.descendant(of: _cell('m'), matching: find.text('25')),
      findsOneWidget,
    );
    // Inside the 36px selection band, sitting on the value's baseline exactly
    // as it does in a closed tile.
    expect(
      tester.getCenter(find.text('m')).dy,
      closeTo(tester.getCenter(_cell('m')).dy, 18),
    );
  });

  testWidgets('the open unit stays open, and tapping another moves it',
      (tester) async {
    await tester.pumpWidget(_host(const Duration(minutes: 25), (_) {}));

    await tester.tap(find.text('m'));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsOneWidget);

    // Tapping the open cell does nothing: there is no collapse.
    await tester.tap(find.text('m'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: _cell('m'),
        matching: find.byType(ListWheelScrollView),
      ),
      findsOneWidget,
    );

    // Tapping a neighbour moves the open state to it.
    await tester.tap(find.text('h'));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    expect(
      find.descendant(
        of: _cell('h'),
        matching: find.byType(ListWheelScrollView),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(_cell('m')).height, 48);
  });

  testWidgets('scrolling the wheel reports the new duration', (tester) async {
    Duration? reported;
    await tester.pumpWidget(
      _host(const Duration(minutes: 25), (d) => reported = d),
    );

    await tester.tap(find.text('m'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, 72));
    await tester.pumpAndSettle();

    expect(reported, const Duration(minutes: 23));
  });
}
