import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../models/task.dart';
import '../providers/defaults_provider.dart';
import '../providers/features_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/duration_picker.dart';
import '../widgets/repeat_picker.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  late Duration _focusDuration;
  late Duration _breakDuration;
  late int _cycles;

  @override
  void initState() {
    super.initState();
    // Reopen on the setup last started, so repeating it is one tap. Nothing is
    // remembered before the first run, and a Settings change clears what is.
    _focusDuration = Duration(
      seconds: ref.read(lastFocusProvider) ?? ref.read(defaultFocusProvider),
    );
    _breakDuration = Duration(
      seconds: ref.read(lastBreakProvider) ?? ref.read(defaultBreakProvider),
    );
    _cycles = ref.read(lastCyclesProvider) ?? 1;
  }

  void _start() {
    HapticFeedback.mediumImpact();
    final focusSecs = _focusDuration.inSeconds.clamp(1, 86399);
    final breakSecs = _breakDuration.inSeconds.clamp(0, 86399);
    ref.read(lastFocusProvider.notifier).set(focusSecs);
    ref.read(lastBreakProvider.notifier).set(breakSecs);
    ref.read(lastCyclesProvider.notifier).set(_cycles);
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
    final home = ref.watch(homeRouteProvider);

    return Scaffold(
      appBar: AppBar(
        // Nothing sits behind this screen when the timer is the only mode, so
        // it carries no back arrow then — and Settings has to be here either
        // way, since the mode picker it otherwise lives on may never be shown.
        automaticallyImplyLeading: false,
        leading: home == '/timer'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => context.go(home),
              ),
        title: const Text('Quick timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Focus for'),
              const SizedBox(height: 8),
              DurationPicker(
                initial: _focusDuration,
                onChanged: (d) => setState(() => _focusDuration = d),
              ),
              const SizedBox(height: 20),
              const _Label('Then break for'),
              const SizedBox(height: 8),
              DurationPicker(
                initial: _breakDuration,
                onChanged: (d) => setState(() => _breakDuration = d),
              ),
              const SizedBox(height: 20),
              const _Label('Repeat'),
              const SizedBox(height: 8),
              RepeatPicker(
                initial: _cycles,
                // Twelve focus/break pairs is a six-hour day of pomodoros;
                // past that nobody is running one uninterrupted session.
                max: 12,
                onChanged: (v) => setState(() => _cycles = v),
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
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
