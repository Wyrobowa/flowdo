import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/defaults_provider.dart';
import '../providers/session_provider.dart';
import '../providers/tasks_provider.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SessionState?>(sessionProvider, (prev, next) {
      if (prev?.phase != next?.phase && next != null) {
        HapticFeedback.mediumImpact();
      }
    });

    final session = ref.watch(sessionProvider);

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(body: SizedBox.shrink());
    }

    if (session.phase == SessionPhase.done) {
      return _DoneScreen(
        cycleCount: session.totalCycles,
        tasksPerCycle: session.tasksPerCycle,
        origin: session.origin,
      );
    }

    return _ActiveSession(session: session, ref: ref);
  }
}

class _ActiveSession extends ConsumerWidget {
  const _ActiveSession({required this.session, required this.ref});

  final SessionState session;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef wRef) {
    final cs = Theme.of(context).colorScheme;
    final task = session.currentTask;
    final isBreak = session.phase == SessionPhase.breakTime;
    final phaseColor = cs.primary;
    final countdownSeconds = wRef.watch(countdownSecondsProvider);

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
              HapticFeedback.lightImpact();
              final origin = session.origin;
              ref.read(sessionProvider.notifier).stop();
              context.go(origin);
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
              currentInCycle: session.indexInCycle + 1,
              tasksPerCycle: session.tasksPerCycle,
              currentCycle: session.currentCycle,
              totalCycles: session.totalCycles,
              color: phaseColor,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: !isBreak && task != null
                        ? Padding(
                            key: ValueKey(task.id),
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                Text(
                                  task.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Builder(builder: (context) {
                                  void doneEarly() {
                                    HapticFeedback.lightImpact();
                                    ref.read(tasksProvider.notifier).markDone(task.id);
                                    ref.read(sessionProvider.notifier).skip();
                                  }

                                  return Semantics(
                                  button: true,
                                  label: 'Mark done early',
                                  onTap: doneEarly,
                                  excludeSemantics: true,
                                  child: GestureDetector(
                                  onTap: doneEarly,
                                  // Padding lifts a 20px row up to the 48dp
                                  // minimum tap target.
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_rounded, size: 13, color: phaseColor.withValues(alpha: 0.4)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Done early',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: phaseColor.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ),
                                  ),
                                  );
                                }),
                                const SizedBox(height: 18),
                              ],
                            ),
                          )
                        : const SizedBox(key: ValueKey('break'), height: 0),
                  ),
                  _CircularTimer(
                    progress: session.progress,
                    secondsRemaining: session.secondsRemaining,
                    color: phaseColor,
                    isRunning: session.isRunning,
                    countdownSeconds: countdownSeconds,
                    phaseLabel: isBreak ? 'Break' : 'Focus',
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
    required this.currentInCycle,
    required this.tasksPerCycle,
    required this.currentCycle,
    required this.totalCycles,
    required this.color,
  });

  final int currentInCycle;
  final int tasksPerCycle;
  final int currentCycle;
  final int totalCycles;
  final Color color;

  String get _semanticLabel {
    final task = 'Task $currentInCycle of $tasksPerCycle';
    return totalCycles > 1
        ? 'Round $currentCycle of $totalCycles, $task'
        : task;
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: _semanticLabel,
        excludeSemantics: true,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            if (totalCycles > 1) ...[
              Text(
                'Round $currentCycle of $totalCycles',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tasksPerCycle, (i) {
                final active = i == currentInCycle - 1;
                final done = i < currentInCycle - 1;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 4,
                    decoration: BoxDecoration(
                      color: done
                          ? color
                          : active
                              ? color.withValues(alpha: 0.5)
                              : context.trackSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        ),
      );
}

class _CircularTimer extends StatefulWidget {
  const _CircularTimer({
    required this.progress,
    required this.secondsRemaining,
    required this.color,
    required this.isRunning,
    required this.countdownSeconds,
    required this.phaseLabel,
  });

  final double progress;
  final int secondsRemaining;
  final Color color;
  final bool isRunning;
  final int countdownSeconds;
  final String phaseLabel;

  @override
  State<_CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<_CircularTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAlpha;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAlpha = Tween<double>(begin: 0.08, end: 0.22)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final m = widget.secondsRemaining ~/ 60;
    final s = widget.secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _spokenTime {
    final m = widget.secondsRemaining ~/ 60;
    final s = widget.secondsRemaining % 60;
    final parts = <String>[
      if (m > 0) '$m minute${m == 1 ? '' : 's'}',
      if (s > 0) '$s second${s == 1 ? '' : 's'}',
    ];
    if (parts.isEmpty) return 'Time up';
    final remaining = '${parts.join(' ')} remaining';
    return widget.isRunning ? remaining : '$remaining, paused';
  }

  bool get _isCountdown =>
      widget.isRunning && widget.secondsRemaining <= widget.countdownSeconds && widget.secondsRemaining > 0;

  @override
  Widget build(BuildContext context) {
    final countdown = _isCountdown;

    return Semantics(
      label: '${widget.phaseLabel} timer',
      value: _spokenTime,
      // Announcing every tick would be unusable, so only the final seconds
      // are live; the rest is read on focus.
      liveRegion: countdown,
      excludeSemantics: true,
      child: AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        return SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isRunning)
                Transform.scale(
                  scale: _pulseScale.value,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: _pulseAlpha.value),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: 240,
                height: 240,
                child: CustomPaint(
                  painter: _TimerPainter(
                    progress: widget.progress,
                    trackColor: context.trackSurface,
                    arcColor: widget.color,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: Tween<double>(begin: 1.45, end: 1.0)
                            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: countdown
                          ? Text(
                              '${widget.secondsRemaining}',
                              key: ValueKey(widget.secondsRemaining),
                              style: TextStyle(
                                fontSize: 96,
                                fontWeight: FontWeight.w700,
                                color: widget.color,
                                letterSpacing: -4,
                              ),
                            )
                          : Text(
                              _timeLabel,
                              key: const ValueKey('time'),
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            final origin = session.origin;
            notifier.stop();
            context.go(origin);
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

    // The circle is icon-only and the caption sits beside it as a separate
    // node, so the whole control is presented as one labelled button.
    void handleTap() {
      HapticFeedback.lightImpact();
      onTap();
    }

    return Semantics(
      button: true,
      label: label,
      onTap: handleTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: handleTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
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
                color:
                    outlined ? cs.onSurface.withValues(alpha: 0.5) : Colors.white,
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
        ),
      ),
    );
  }
}

class _DoneScreen extends StatefulWidget {
  const _DoneScreen({
    required this.cycleCount,
    required this.tasksPerCycle,
    required this.origin,
  });

  final int cycleCount;
  final int tasksPerCycle;
  final String origin;

  @override
  State<_DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends State<_DoneScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _enter, curve: Curves.elasticOut),
    );
    _fade = CurveTween(curve: const Interval(0.0, 0.5, curve: Curves.easeOut))
        .animate(_enter);
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  String get _subtitle {
    if (widget.cycleCount > 1 && widget.tasksPerCycle == 1) {
      return '${widget.cycleCount} rounds complete.\nGreat work!';
    }
    if (widget.cycleCount > 1) {
      return '${widget.cycleCount} rounds, ${widget.tasksPerCycle} tasks each.\nGreat work!';
    }
    return 'You finished ${widget.tasksPerCycle} task${widget.tasksPerCycle == 1 ? '' : 's'}.\nGreat work!';
  }

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
                ScaleTransition(
                  scale: _scale,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, size: 48, color: cs.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Session complete!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  _subtitle,
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
                      context.go(widget.origin);
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
