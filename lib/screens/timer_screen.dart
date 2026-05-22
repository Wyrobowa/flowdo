import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../models/task.dart';
import '../providers/defaults_provider.dart';
import '../providers/session_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  late int _focusMinutes;
  late int _breakMinutes;

  static const _focusOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90];
  static const _breakOptions = [0, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _focusMinutes = ref.read(defaultFocusProvider);
    _breakMinutes = ref.read(defaultBreakProvider);
  }

  void _start() {
    final task = Task(
      title: 'Focus',
      focusMinutes: _focusMinutes,
      breakMinutes: _breakMinutes,
    );
    ref.read(sessionProvider.notifier).start([task]);
    context.go('/session');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Quick timer'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label('Focus for'),
              const SizedBox(height: 12),
              _ChipRow(
                options: _focusOptions,
                selected: _focusMinutes,
                label: (v) => '${v}m',
                activeColor: cs.primary,
                onSelected: (v) => setState(() => _focusMinutes = v),
              ),
              const SizedBox(height: 32),
              _Label('Then break for'),
              const SizedBox(height: 12),
              _ChipRow(
                options: _breakOptions,
                selected: _breakMinutes,
                label: (v) => v == 0 ? 'None' : '${v}m',
                activeColor: cs.secondary,
                onSelected: (v) => setState(() => _breakMinutes = v),
              ),
              const Spacer(),
              _Preview(focusMinutes: _focusMinutes, breakMinutes: _breakMinutes),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start timer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      );
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.activeColor,
    required this.onSelected,
  });

  final List<int> options;
  final int selected;
  final String Function(int) label;
  final Color activeColor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((v) {
        final sel = v == selected;
        return GestureDetector(
          onTap: () => onSelected(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? activeColor : context.chipSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label(v),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : cs.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.focusMinutes, required this.breakMinutes});

  final int focusMinutes;
  final int breakMinutes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: context.trackSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PreviewPill(
            icon: Icons.timer_outlined,
            label: '${focusMinutes}m focus',
            color: cs.primary,
          ),
          if (breakMinutes > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ),
            _PreviewPill(
              icon: Icons.coffee_outlined,
              label: '${breakMinutes}m break',
              color: cs.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
}
