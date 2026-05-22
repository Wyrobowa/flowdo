import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../providers/features_provider.dart';
import '../providers/groups_provider.dart';
import '../providers/tasks_provider.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(featuresProvider);
    final tasks = ref.watch(tasksProvider);
    final groups = ref.watch(groupsProvider);
    final pendingTasks = tasks.where((t) => !t.isDone).length;
    final accent = Theme.of(context).colorScheme.primary;

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
                  badge: pendingTasks > 0
                      ? '$pendingTasks task${pendingTasks == 1 ? '' : 's'}'
                      : null,
                  onTap: () => context.go('/tasks'),
                ),
                const SizedBox(height: 14),
              ],
              if (features.groups)
                _ModeCard(
                  color: accent,
                  icon: Icons.folder_open_rounded,
                  title: 'Groups & tasks',
                  description: 'Organise your work into groups like Work or Personal.',
                  badge: groups.isNotEmpty
                      ? '${groups.length} group${groups.length == 1 ? '' : 's'}'
                      : null,
                  onTap: () => context.go('/groups'),
                ),
            ],
          ),
        ),
      ),
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
  });

  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: context.cardSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
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
    );
  }
}
