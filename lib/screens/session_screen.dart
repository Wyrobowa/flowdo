import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/tasks_provider.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(body: SizedBox.shrink());
    }

    if (session.phase == SessionPhase.done) {
      return _DoneScreen(taskCount: session.tasks.length);
    }

    return _ActiveSession(session: session, ref: ref);
  }
}

class _ActiveSession extends StatelessWidget {
  const _ActiveSession({required this.session, required this.ref});

  final SessionState session;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final task = session.currentTask;
    final isBreak = session.phase == SessionPhase.breakTime;
    final phaseColor = isBreak ? cs.secondary : cs.primary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isBreak ? 'Break' : 'Focus',
          style: TextStyle(color: phaseColor, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(sessionProvider.notifier).stop();
              context.go('/');
            },
            child: const Text('End session'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _TaskProgress(
              current: session.currentIndex + 1,
              total: session.tasks.length,
              color: phaseColor,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isBreak && task != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        task.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                  _CircularTimer(
                    progress: session.progress,
                    secondsRemaining: session.secondsRemaining,
                    color: phaseColor,
                  ),
                ],
              ),
            ),
            _Controls(session: session, ref: ref, phaseColor: phaseColor),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TaskProgress extends StatelessWidget {
  const _TaskProgress({
    required this.current,
    required this.total,
    required this.color,
  });

  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final active = i == current - 1;
            final done = i < current - 1;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 4,
                decoration: BoxDecoration(
                  color: done
                      ? color
                      : active
                          ? color.withValues(alpha: 0.5)
                          : const Color(0xFFEDE9E4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      );
}

class _CircularTimer extends StatelessWidget {
  const _CircularTimer({
    required this.progress,
    required this.secondsRemaining,
    required this.color,
  });

  final double progress;
  final int secondsRemaining;
  final Color color;

  String get _timeLabel {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _TimerPainter(
          progress: progress,
          trackColor: const Color(0xFFEDE9E4),
          arcColor: color,
        ),
        child: Center(
          child: Text(
            _timeLabel,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w300,
              letterSpacing: -2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  const _TimerPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
  });

  final double progress;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.arcColor != arcColor;
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.session,
    required this.ref,
    required this.phaseColor,
  });

  final SessionState session;
  final WidgetRef ref;
  final Color phaseColor;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(sessionProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.skip_next_rounded,
          label: 'Skip',
          onTap: notifier.skip,
          outlined: true,
        ),
        const SizedBox(width: 16),
        _ControlButton(
          icon: session.isRunning
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          label: session.isRunning ? 'Pause' : 'Resume',
          onTap: notifier.togglePause,
          color: phaseColor,
          large: true,
        ),
        const SizedBox(width: 16),
        _ControlButton(
          icon: Icons.stop_rounded,
          label: 'Stop',
          onTap: () {
            notifier.stop();
            context.go('/');
          },
          outlined: true,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.outlined = false,
    this.large = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool outlined;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurface.withValues(alpha: 0.6);
    final size = large ? 72.0 : 56.0;
    final iconSize = large ? 32.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: outlined ? Colors.transparent : effectiveColor,
              shape: BoxShape.circle,
              border: outlined
                  ? Border.all(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: outlined ? cs.onSurface.withValues(alpha: 0.5) : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DoneScreen extends StatelessWidget {
  const _DoneScreen({required this.taskCount});

  final int taskCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, size: 48, color: cs.primary),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Session complete!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'You finished $taskCount task${taskCount == 1 ? '' : 's'}.\nGreat work!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Consumer(
                  builder: (_, ref, _) => FilledButton.icon(
                    onPressed: () {
                      ref.read(tasksProvider.notifier).resetDone();
                      ref.read(sessionProvider.notifier).stop();
                      context.go('/');
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Back to home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
