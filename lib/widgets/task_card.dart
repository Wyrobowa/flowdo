import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../extensions.dart';
import '../models/task.dart';
import '../providers/tasks_provider.dart';
import 'add_task_sheet.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task, required this.index});

  final Task task;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(tasksProvider.notifier).remove(task.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEdit(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(tasksProvider.notifier).toggleDone(task.id);
                  },
                  child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: task.isDone
                        ? cs.primary.withValues(alpha: 0.15)
                        : context.chipSurface,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: task.isDone
                        ? Icon(Icons.check, key: const ValueKey('done'), size: 16, color: cs.primary)
                        : Center(
                            key: ValueKey(index),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                  ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: task.isDone
                              ? cs.onSurface.withValues(alpha: 0.4)
                              : cs.onSurface,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        child: Text(task.title),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TimeChip(
                            icon: Icons.timer_outlined,
                            label: Duration(seconds: task.focusSeconds).pretty,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          if (task.breakSeconds > 0) ...[
                            const SizedBox(width: 6),
                            _TimeChip(
                              icon: Icons.coffee_outlined,
                              label: '${Duration(seconds: task.breakSeconds).pretty} break',
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ],
                        ],
                      ),
                      if (task.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.notes,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: cs.onSurface.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddTaskSheet(task: task),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
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
          Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
}
