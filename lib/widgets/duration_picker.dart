import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../extensions.dart';

const _units = [('h', 24), ('m', 60), ('s', 60)];

/// Compact h/m/s picker: shows a single row of unit tiles and only reveals a
/// scroll wheel for the unit the user taps.
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

  void _toggle(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_open == index) {
        _open = null;
        _ctrl?.dispose();
        _ctrl = null;
        return;
      }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < _units.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _UnitTile(
                  value: _values[i],
                  label: _units[i].$1,
                  open: _open == i,
                  onTap: () => _toggle(i),
                ),
              ),
            ],
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      for (var i = 0; i < _units.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: i == _open
                              ? _Wheel(
                                  ctrl: _ctrl!,
                                  count: _units[i].$2,
                                  selected: _values[i],
                                  onChanged: _select,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.value,
    required this.label,
    required this.open,
    required this.onTap,
  });

  final int value;
  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        decoration: BoxDecoration(
          color: open ? cs.primary.withValues(alpha: 0.12) : context.chipSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: open ? cs.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: open || value > 0
                    ? (open ? cs.primary : cs.onSurface)
                    : cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: open
                    ? cs.primary.withValues(alpha: 0.7)
                    : cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.ctrl,
    required this.count,
    required this.selected,
    required this.onChanged,
  });

  final FixedExtentScrollController ctrl;
  final int count;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: ctrl,
            itemExtent: 36,
            diameterRatio: 1.4,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (_, index) {
                final sel = index == selected;
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: sel ? 21 : 15,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
