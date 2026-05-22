import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late int _h, _m, _s;
  late final FixedExtentScrollController _hCtrl, _mCtrl, _sCtrl;

  @override
  void initState() {
    super.initState();
    _h = widget.initial.inHours.clamp(0, 23);
    _m = widget.initial.inMinutes.remainder(60);
    _s = widget.initial.inSeconds.remainder(60);
    _hCtrl = FixedExtentScrollController(initialItem: _h);
    _mCtrl = FixedExtentScrollController(initialItem: _m);
    _sCtrl = FixedExtentScrollController(initialItem: _s);
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _mCtrl.dispose();
    _sCtrl.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(
        Duration(hours: _h, minutes: _m, seconds: _s),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Wheel(
          ctrl: _hCtrl,
          count: 24,
          label: 'h',
          onChanged: (v) {
            setState(() => _h = v);
            _notify();
          },
        ),
        const SizedBox(width: 8),
        _Wheel(
          ctrl: _mCtrl,
          count: 60,
          label: 'm',
          onChanged: (v) {
            setState(() => _m = v);
            _notify();
          },
        ),
        const SizedBox(width: 8),
        _Wheel(
          ctrl: _sCtrl,
          count: 60,
          label: 's',
          onChanged: (v) {
            setState(() => _s = v);
            _notify();
          },
        ),
      ],
    );
  }
}

class _Wheel extends StatefulWidget {
  const _Wheel({
    required this.ctrl,
    required this.count,
    required this.label,
    required this.onChanged,
  });

  final FixedExtentScrollController ctrl;
  final int count;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.ctrl.initialItem;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListWheelScrollView.useDelegate(
                  controller: widget.ctrl,
                  itemExtent: 40,
                  diameterRatio: 1.3,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = i);
                    widget.onChanged(i);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.count,
                    builder: (_, index) {
                      final sel = index == _selected;
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: sel ? 22 : 15,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w400,
                            color: sel
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.25),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
