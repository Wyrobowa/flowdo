import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdo/widgets/duration_picker.dart';

Widget _host(Duration initial, ValueChanged<Duration> onChanged) => MaterialApp(
      home: Scaffold(
        body: DurationPicker(initial: initial, onChanged: onChanged),
      ),
    );

void main() {
  testWidgets('starts collapsed with one tile per unit', (tester) async {
    await tester.pumpWidget(_host(const Duration(minutes: 25), (_) {}));

    expect(find.text('h'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
    expect(find.text('s'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.byType(ListWheelScrollView), findsNothing);
  });

  testWidgets('tapping a unit reveals its wheel, tapping again hides it',
      (tester) async {
    await tester.pumpWidget(_host(const Duration(minutes: 25), (_) {}));

    await tester.tap(find.text('m'));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsOneWidget);

    await tester.tap(find.text('m'));
    await tester.pumpAndSettle();
    expect(find.byType(ListWheelScrollView), findsNothing);
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
