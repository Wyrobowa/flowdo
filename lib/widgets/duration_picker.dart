import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../extensions.dart';

const _units = [('h', 24), ('m', 60), ('s', 60)];
const _spokenUnit = {'h': 'hours', 'm': 'minutes', 's': 'seconds'};

const _itemExtent = 36.0;
// Three visible items; the open cell is exactly the wheel, with no chrome
// above or below it to pad the height out.
const _openHeight = _itemExtent * 3;

/// Compact h/m/s picker: a row of unit tiles in which the tapped tile becomes
/// the scroll wheel in place. The other two keep their height and their exact
/// offset, so switching units never moves the target out from under the finger.
class DurationPicker extends StatefulWidget {
  const DurationPicker({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final Duration initial;
  final ValueChanged<Duration> onChanged;

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late List<int> _values;
  int? _open;
  FixedExtentScrollController? _ctrl;

  @override
  void initState() {
    super.initState();
    _values = [
      widget.initial.inHours.clamp(0, 23),
      widget.initial.inMinutes.remainder(60),
      widget.initial.inSeconds.remainder(60),
    ];
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  /// Opens [index]. There is no collapse: with every value on screen the whole
  /// time, closing carries no information, and a close target cannot reach 48dp
  /// inside a cell a third of the picker wide.
  void _openUnit(int index) {
    if (_open == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _open = index;
      _ctrl?.dispose();
      _ctrl = FixedExtentScrollController(initialItem: _values[index]);
    });
  }

  void _select(int value) {
    if (_values[_open!] == value) return;
    HapticFeedback.selectionClick();
    setState(() => _values[_open!] = value);
    widget.onChanged(Duration(
      hours: _values[0],
      minutes: _values[1],
      seconds: _values[2],
    ));
  }

  /// Backs the open cell's increase/decrease actions, so the wheel is operable
  /// without a swipe gesture.
  void _step(int delta) {
    final index = _open!;
    final next = (_values[index] + delta).clamp(0, _units[index].$2 - 1);
    if (next == _values[index]) return;
    _ctrl!.animateToItem(
      next,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      // The open cell grows downward from a fixed top edge; its neighbours stay
      // 48 tall and stay put.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _units.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open == i
                  ? _OpenUnit(
                      ctrl: _ctrl!,
                      count: _units[i].$2,
                      unit: _units[i].$1,
                      value: _values[i],
                      onChanged: _select,
                      onIncrease: () => _step(1),
                      onDecrease: () => _step(-1),
                    )
                  : _UnitTile(
                      value: _values[i],
                      unit: _units[i].$1,
                      onTap: () => _openUnit(i),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.value,
    required this.unit,
    required this.onTap,
  });

  final int value;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      // Only the open unit is selected, and an open unit is a wheel, so a tile
      // is always the unselected half of the pair.
      selected: false,
      label: '$value ${_spokenUnit[unit] ?? unit}',
      hint: 'Adjust',
      // excludeSemantics drops the child's tap action, so re-declare it here.
      // Safe on a closed tile, which has no interactive children.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: context.chipSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          // Align with a height factor, not Center: Center would expand to the
          // tallest the incoming constraints allow.
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: _Readout(
              value: value,
              unit: unit,
              fontSize: 20,
              valueColor: value > 0
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.35),
              unitColor: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenUnit extends StatelessWidget {
  const _OpenUnit({
    required this.ctrl,
    required this.count,
    required this.unit,
    required this.value,
    required this.onChanged,
    required this.onIncrease,
    required this.onDecrease,
  });

  final FixedExtentScrollController ctrl;
  final int count;
  final String unit;
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      // No excludeSemantics here: around a live wheel it would swallow every
      // value. explicitChildNodes keeps this cell one labelled node with the
      // wheel's own nodes underneath it.
      container: true,
      explicitChildNodes: true,
      selected: true,
      label: '$value ${_spokenUnit[unit] ?? unit}',
      hint: 'Swipe up or down to adjust',
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: SizedBox(
        height: _openHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.chipSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Container(
                height: _itemExtent,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: ctrl,
              itemExtent: _itemExtent,
              diameterRatio: 1.4,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: count,
                builder: (_, index) => Center(
                  // The unit glyph has no tile to live in any more, so it rides
                  // in the selection band: the centred item is the closed tile's
                  // content, off-centre items are bare dimmed digits.
                  child: index == value
                      ? _Readout(
                          value: index,
                          unit: unit,
                          fontSize: 21,
                          valueColor: cs.primary,
                          unitColor: cs.primary.withValues(alpha: 0.7),
                        )
                      : Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: cs.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The `25 m` arrangement, shared by the closed tile and the selection band.
class _Readout extends StatelessWidget {
  const _Readout({
    required this.value,
    required this.unit,
    required this.fontSize,
    required this.valueColor,
    required this.unitColor,
  });

  final int value;
  final String unit;
  final double fontSize;
  final Color valueColor;
  final Color unitColor;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: valueColor,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: unitColor,
            ),
          ),
        ],
      );
}
