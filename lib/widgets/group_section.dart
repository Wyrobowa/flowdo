import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../models/task_group.dart';
import '../providers/groups_provider.dart';
import '../providers/session_provider.dart';
import '../providers/tasks_provider.dart';
import 'add_group_sheet.dart';
import 'add_task_sheet.dart';
import 'task_card.dart';

class GroupSection extends ConsumerWidget {
  const GroupSection({
    super.key,
    required this.group,
    required this.tasks,
  });

  final TaskGroup group;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pending = tasks.where((t) => !t.isDone).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: group.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                '${tasks.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (pending.isNotEmpty) ...[
                const SizedBox(width: 6),
                Material(
                  color: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      ref.read(sessionProvider.notifier).start(pending);
                      context.go('/session');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
              PopupMenuButton<_Action>(
                onSelected: (a) => _onAction(context, ref, a),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _Action.addTask,
                    child: Text('Add task'),
                  ),
                  PopupMenuItem(
                    value: _Action.edit,
                    child: Text('Edit group'),
                  ),
                  PopupMenuItem(
                    value: _Action.delete,
                    child: Text('Delete group'),
                  ),
                ],
                icon: Icon(
                  Icons.more_horiz,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
            child: GestureDetector(
              onTap: () => _openAddTask(context, groupId: group.id),
              child: Text(
                'No tasks yet · tap to add one',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.35),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) =>
                ref.read(tasksProvider.notifier).reorderGroup(group.id, oldIndex, newIndex),
            itemBuilder: (_, i) => TaskCard(
              key: ValueKey(tasks[i].id),
              task: tasks[i],
              index: i,
            ),
          ),
      ],
    );
  }

  void _onAction(BuildContext context, WidgetRef ref, _Action action) {
    switch (action) {
      case _Action.addTask:
        _openAddTask(context, groupId: group.id);
      case _Action.edit:
        _openEditGroup(context);
      case _Action.delete:
        _confirmDelete(context, ref);
    }
  }

  void _openAddTask(BuildContext context, {String? groupId}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => AddTaskSheet(initialGroupId: groupId),
      );

  void _openEditGroup(BuildContext context) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => AddGroupSheet(group: group),
      );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text(
          tasks.isEmpty
              ? 'Delete "${group.name}"?'
              : '"${group.name}" will be removed and its tasks will become ungrouped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(tasksProvider.notifier).ungroupByGroupId(group.id);
      ref.read(groupsProvider.notifier).remove(group.id);
    }
  }
}

enum _Action { addTask, edit, delete }
