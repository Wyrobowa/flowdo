import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../extensions.dart';

const _glyph = '×';

const _itemExtent = 36.0;
// Three visible items; the open cell is exactly the wheel, with no chrome
// above or below it to pad the height out.
const _openHeight = _itemExtent * 3;

String _spoken(int value) => value == 1 ? 'Repeat once' : 'Repeat $value times';

/// How many times to run the thing being repeated: one compact tile that
/// becomes the scroll wheel in place when tapped, the way a [DurationPicker]
/// unit does.
///
/// The tile takes the first of three notional columns, so Repeat lines up with
/// a single duration unit instead of stretching across the row.
class RepeatPicker extends StatefulWidget {
  const RepeatPicker({
    super.key,
    required this.initial,
    required this.max,
    required this.onChanged,
    this.compact = false,
  });

  /// Starting count. 1 means "run it once", not "off".
  final int initial;

  /// Highest count on the wheel. The two call sites repeat different things —
  /// one focus/break pair, or a whole task list — so they cap differently.
  final int max;

  final ValueChanged<int> onChanged;

  /// Tightens the tile's type and padding for the tasks bottom bar. It never
  /// changes behaviour, the wheel, or the tap target.
  final bool compact;

  @override
  State<RepeatPicker> createState() => _RepeatPickerState();
}

class _RepeatPickerState extends State<RepeatPicker> {
  late int _value;
  bool _open = false;
  FixedExtentScrollController? _ctrl;

  @override
  void initState() {
    super.initState();
    _value = widget.initial.clamp(1, widget.max);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  /// Opens the wheel, and there is no way back. The duration picker's escape
  /// hatch is tapping a neighbouring unit, which closes the current one by
  /// opening another; Repeat is a single tile with no neighbour, and a close
  /// target cannot reach 48dp inside the open cell. The value stays on screen
  /// in the selection band either way, so staying open hides nothing.
  void _openWheel() {
    if (_open) return;
    HapticFeedback.selectionClick();
    setState(() {
      _open = true;
      _ctrl = FixedExtentScrollController(initialItem: _value - 1);
    });
  }

  void _select(int value) {
    if (_value == value) return;
    HapticFeedback.selectionClick();
    setState(() => _value = value);
    widget.onChanged(value);
  }

  /// Backs the open cell's increase/decrease actions, so the wheel is operable
  /// without a swipe gesture.
  void _step(int delta) {
    final next = (_value + delta).clamp(1, widget.max);
    if (next == _value) return;
    _ctrl!.animateToItem(
      next - 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      // The cell grows downward from a fixed top edge, like a duration unit.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? _OpenCount(
                    ctrl: _ctrl!,
                    max: widget.max,
                    value: _value,
                    compact: widget.compact,
                    onChanged: (index) => _select(index + 1),
                    onIncrease: () => _step(1),
                    onDecrease: () => _step(-1),
                  )
                : _CountTile(
                    value: _value,
                    compact: widget.compact,
                    onTap: _openWheel,
                  ),
          ),
        ),
        // Two empty columns on the duration picker's grid: the tile is a third
        // of the row, not the whole of it.
        const SizedBox(width: 8),
        const Spacer(),
        const SizedBox(width: 8),
        const Spacer(),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.value,
    required this.compact,
    required this.onTap,
  });

  final int value;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      // The tile is the closed half of the pair; only the wheel is selected.
      selected: false,
      label: _spoken(value),
      hint: 'Adjust',
      // excludeSemantics drops the child's tap action, so re-declare it here.
      // Safe on a closed tile, which has no interactive children.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
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
              fontSize: compact ? 15 : 20,
              // No dimmed-at-1 state: 1 is "once", a real count, not "off".
              valueColor: cs.onSurface,
              glyphColor: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenCount extends StatelessWidget {
  const _OpenCount({
    required this.ctrl,
    required this.max,
    required this.value,
    required this.compact,
    required this.onChanged,
    required this.onIncrease,
    required this.onDecrease,
  });

  final FixedExtentScrollController ctrl;
  final int max;
  final int value;
  final bool compact;
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
      label: _spoken(value),
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
                childCount: max,
                builder: (_, index) => Center(
                  // The glyph rides in the selection band: the centred item is
                  // the closed tile's content, off-centre items are bare
                  // dimmed digits.
                  child: index == value - 1
                      ? _Readout(
                          value: index + 1,
                          fontSize: compact ? 16 : 21,
                          valueColor: cs.primary,
                          glyphColor: cs.primary.withValues(alpha: 0.7),
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: compact ? 13 : 15,
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

/// The `3 ×` arrangement, shared by the closed tile and the selection band.
/// Counts are not zero-padded: `03 ×` would read as a clock, not a count.
class _Readout extends StatelessWidget {
  const _Readout({
    required this.value,
    required this.fontSize,
    required this.valueColor,
    required this.glyphColor,
  });

  final int value;
  final double fontSize;
  final Color valueColor;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: valueColor,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            _glyph,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: glyphColor,
            ),
          ),
        ],
      );
}
