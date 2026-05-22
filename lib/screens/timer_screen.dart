import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../models/task.dart';
import '../providers/defaults_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/duration_picker.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  late Duration _focusDuration;
  late Duration _breakDuration;
  int _cycles = 1;

  static const _cycleOptions = [1, 2, 3, 4, 5, 6, 8];

  @override
  void initState() {
    super.initState();
    _focusDuration = Duration(seconds: ref.read(defaultFocusProvider));
    _breakDuration = Duration(seconds: ref.read(defaultBreakProvider));
  }

  void _start() {
    HapticFeedback.mediumImpact();
    final focusSecs = _focusDuration.inSeconds.clamp(30, 86399);
    final breakSecs = _breakDuration.inSeconds.clamp(0, 86399);
    final task = Task(
      title: 'Focus',
      focusSeconds: focusSecs,
      breakSeconds: breakSecs,
    );
    final tasks = List.generate(_cycles, (_) => task);
    ref.read(sessionProvider.notifier).start(
      tasks,
      cycleSize: _cycles > 1 ? 1 : 0,
      origin: '/timer',
    );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Focus for'),
              const SizedBox(height: 12),
              DurationPicker(
                initial: _focusDuration,
                onChanged: (d) => setState(() => _focusDuration = d),
              ),
              const SizedBox(height: 28),
              const _Label('Then break for'),
              const SizedBox(height: 12),
              DurationPicker(
                initial: _breakDuration,
                onChanged: (d) => setState(() => _breakDuration = d),
              ),
              const SizedBox(height: 28),
              const _Label('Repeat'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cycleOptions.map((v) {
                  final sel = v == _cycles;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _cycles = v);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? cs.primary : context.chipSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${v}×',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : cs.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              _Preview(
                focusDuration: _focusDuration,
                breakDuration: _breakDuration,
                cycles: _cycles,
              ),
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

class _Preview extends StatelessWidget {
  const _Preview({
    required this.focusDuration,
    required this.breakDuration,
    required this.cycles,
  });

  final Duration focusDuration;
  final Duration breakDuration;
  final int cycles;

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
            label: '${focusDuration.pretty} focus',
            color: cs.primary,
          ),
          if (breakDuration.inSeconds > 0) ...[
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
              label: '${breakDuration.pretty} break',
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ],
          if (cycles > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ),
            _PreviewPill(
              icon: Icons.repeat_rounded,
              label: '×$cycles',
              color: cs.onSurface.withValues(alpha: 0.5),
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
