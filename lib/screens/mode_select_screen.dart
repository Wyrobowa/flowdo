import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../providers/groups_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/theme_provider.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final groups = ref.watch(groupsProvider);
    final pendingTasks = tasks.where((t) => !t.isDone).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_ThemeToggle()],
              ),
              const SizedBox(height: 16),
              const Text(
                'Flowdo',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How do you want to work today?',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 40),
              _ModeCard(
                color: const Color(0xFFE05A2B),
                icon: Icons.timer_outlined,
                title: 'Quick timer',
                description: 'Set a duration and start focusing — no setup needed.',
                badge: null,
                onTap: () => context.go('/timer'),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                color: const Color(0xFF3B82F6),
                icon: Icons.checklist_rounded,
                title: 'Tasks & breaks',
                description: 'Add tasks with custom focus time and breaks.',
                badge: pendingTasks > 0
                    ? '$pendingTasks task${pendingTasks == 1 ? '' : 's'}'
                    : null,
                onTap: () => context.go('/tasks'),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                color: const Color(0xFFA855F7),
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

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final (icon, next, tooltip) = switch (mode) {
      ThemeMode.light  => (Icons.dark_mode_outlined,       ThemeMode.dark,   'Switch to dark'),
      ThemeMode.dark   => (Icons.brightness_auto_outlined, ThemeMode.system, 'Follow system'),
      ThemeMode.system => (Icons.light_mode_outlined,      ThemeMode.light,  'Switch to light'),
    };
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => ref.read(themeModeProvider.notifier).set(next),
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
