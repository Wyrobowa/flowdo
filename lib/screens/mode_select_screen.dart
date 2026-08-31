import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../providers/features_provider.dart';
import '../providers/session_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/tasks_provider.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(featuresProvider);
    final pending = ref.watch(pendingTasksProvider);
    final pendingLabel =
        '${pending.length} task${pending.length == 1 ? '' : 's'}';
    final accent = Theme.of(context).colorScheme.primary;
    final stats = ref.watch(statsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Flowdo',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'How do you want to work today?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () => context.go('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (features.timer) ...[
                _ModeCard(
                  color: accent,
                  icon: Icons.timer_outlined,
                  title: 'Quick timer',
                  description: 'Set a duration and start focusing — no setup needed.',
                  badge: null,
                  onTap: () => context.go('/timer'),
                ),
                const SizedBox(height: 14),
              ],
              if (features.tasks) ...[
                _ModeCard(
                  color: accent,
                  icon: Icons.checklist_rounded,
                  title: 'Tasks & breaks',
                  description: 'Add tasks with custom focus time and breaks.',
                  badge: pending.isEmpty ? null : pendingLabel,
                  onTap: () => context.go('/tasks'),
                  // A single pass of the pending list, the way the Start bar
                  // runs it at a repeat of one. Anything else is a trip to
                  // the list and its repeat picker.
                  onPlay: pending.isEmpty
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          ref.read(sessionProvider.notifier).start(
                                pending,
                                cycleSize: 0,
                                origin: '/tasks',
                              );
                          context.go('/session');
                        },
                  playLabel: 'Start $pendingLabel',
                ),
                const SizedBox(height: 14),
              ],
              if (stats.hasStats) ...[
                const SizedBox(height: 8),
                _StatsRow(stats: stats),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final StatsState stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBadge(
          icon: Icons.check_circle_outline,
          label: '${stats.totalSessions} session${stats.totalSessions == 1 ? '' : 's'}',
        ),
        if (stats.currentStreak > 1) ...[
          const SizedBox(width: 14),
          _StatBadge(
            icon: Icons.local_fire_department_outlined,
            label: '${stats.currentStreak}d streak',
            highlighted: true,
          ),
        ],
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label, this.highlighted = false});
  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = highlighted ? cs.primary : cs.onSurface.withValues(alpha: 0.4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
    this.onPlay,
    this.playLabel,
  }) : assert(onPlay == null || playLabel != null,
            'A play control needs a label of its own');

  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  /// Runs what the card is a summary of, without opening it. Omitted when
  /// there is nothing to run.
  final VoidCallback? onPlay;
  final String? playLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: context.cardSurface,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          // InkWell gives a tap action but no button role, and the badge would
          // otherwise be read as a stray fragment. The merge covers the body
          // alone, not the whole card: the play control stands beside it as a
          // node of its own, where a descendant would be swallowed here.
          Expanded(
            child: Semantics(
              button: true,
              label: [title, description, if (badge != null) badge].join(', '),
              onTap: onTap,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(20, 20, onPlay == null ? 20 : 8, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.5),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (badge != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: cs.onSurface.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onPlay != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _PlayButton(
                color: color,
                label: playLabel!,
                onPressed: onPlay!,
              ),
            ),
        ],
      ),
    );
  }
}

/// Starts a mode's stored setup from its card. A control in its own right, so
/// it carries its own role, label and tap action rather than leaning on the
/// card's — the exclusion around the card body would swallow the button
/// underneath, leaving a target a screen reader can see but not press.
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.color,
    required this.label,
    required this.onPressed,
  });

  final Color color;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded),
        // The padded tap target holds the 48dp box around the smaller disc.
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
        ),
      ),
    );
  }
}
