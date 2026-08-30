import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowdo/screens/timer_screen.dart';
import 'package:flowdo/theme.dart';
import 'package:flowdo/widgets/duration_picker.dart';
import 'package:flowdo/widgets/repeat_picker.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(theme: appTheme, home: const TimerScreen())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the sections stack compactly', (tester) async {
    await pumpScreen(tester);

    final focus = tester.getTopLeft(find.text('Focus for')).dy;
    final rest = tester.getTopLeft(find.text('Then break for')).dy;
    final repeat = tester.getTopLeft(find.text('Repeat')).dy;

    // A section is label 20 + gap 8 + picker 48 = 76, with 20 between them.
    expect(tester.getSize(find.text('Focus for')).height, 20);
    expect(tester.getSize(find.byType(DurationPicker).first).height, 48);
    expect(rest - focus, 96);
    expect(repeat - focus, 192);

    // Repeat is now a section like the two above it. The chips it replaces
    // wrapped to 290 x 106 at 390pt.
    expect(tester.getSize(find.byType(RepeatPicker)).height, 48);
  });

  testWidgets('the repeat tile opens in place, pushing the rest down by 60',
      (tester) async {
    await pumpScreen(tester);

    final startButtonBefore = tester.getTopLeft(find.byType(FilledButton)).dy;

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    // The tile became the wheel: one section, grown by the same 60 a duration
    // unit grows by, with no second row underneath it.
    expect(tester.getSize(find.byType(RepeatPicker)).height, 108);
    expect(find.byType(ListWheelScrollView), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(FilledButton)).dy - startButtonBefore,
      60,
    );
  });

  testWidgets('opening a picker grows it in place, pushing the rest down by 60',
      (tester) async {
    await pumpScreen(tester);

    final repeatBefore = tester.getTopLeft(find.text('Repeat')).dy;
    final breakPickerBefore = tester.getTopLeft(find.byType(DurationPicker).last);

    await tester.tap(find.text('m').first);
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(DurationPicker).first).height, 108);
    expect(tester.getTopLeft(find.text('Repeat')).dy - repeatBefore, 60);
    expect(
      tester.getTopLeft(find.byType(DurationPicker).last).dy -
          breakPickerBefore.dy,
      60,
    );
  });
}
