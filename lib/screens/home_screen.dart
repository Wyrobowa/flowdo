import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../models/task.dart';
import '../models/task_group.dart';
import '../providers/groups_provider.dart';
import '../providers/session_provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/add_group_sheet.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/group_section.dart';
import '../widgets/task_card.dart';

enum HomeMode { tasks, groups }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.mode});

  final HomeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final tasks = ref.watch(tasksProvider);
    final pending = ref.watch(pendingTasksProvider);
    final doneCount = tasks.where((t) => t.isDone).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(mode == HomeMode.tasks ? 'Tasks & breaks' : 'Groups & tasks'),
        actions: [
          if (doneCount > 0)
            TextButton.icon(
              onPressed: () => ref.read(tasksProvider.notifier).resetDone(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
            ),
          if (mode == HomeMode.groups)
            IconButton(
              onPressed: () => _openGroupSheet(context),
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'New group',
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: mode == HomeMode.tasks
          ? _TasksBody(tasks: tasks, onAddTask: () => _openTaskSheet(context))
          : _GroupsBody(
              groups: groups,
              tasks: tasks,
              onAddGroup: () => _openGroupSheet(context),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskSheet(context),
        child: const Icon(Icons.add),
      ),
      bottomSheet: pending.isEmpty
          ? null
          : _StartSessionBar(pendingCount: pending.length),
    );
  }

  void _openTaskSheet(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const AddTaskSheet(),
      );

  void _openGroupSheet(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const AddGroupSheet(),
      );
}

// ── Tasks mode ────────────────────────────────────────────────────────────────

class _TasksBody extends ConsumerWidget {
  const _TasksBody({required this.tasks, required this.onAddTask});

  final List<Task> tasks;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return _EmptyState(
        icon: Icons.checklist_rounded,
        color: const Color(0xFF3B82F6),
        title: 'No tasks yet',
        description: 'Add tasks with custom focus time\nand breaks, then start your flow.',
        actionLabel: 'Add first task',
        onAction: onAddTask,
      );
    }
    return Column(
      children: [
        _ProgressHeader(tasks: tasks),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) =>
                ref.read(tasksProvider.notifier).reorder(oldIndex, newIndex),
            itemBuilder: (_, i) => TaskCard(
              key: ValueKey(tasks[i].id),
              task: tasks[i],
              index: i,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Groups mode ───────────────────────────────────────────────────────────────

class _GroupsBody extends ConsumerWidget {
  const _GroupsBody({
    required this.groups,
    required this.tasks,
    required this.onAddGroup,
  });

  final List<TaskGroup> groups;
  final List<Task> tasks;
  final VoidCallback onAddGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ungrouped = tasks.where((t) => t.groupId == null).toList();

    if (groups.isEmpty && ungrouped.isEmpty) {
      return _EmptyState(
        icon: Icons.folder_open_rounded,
        color: const Color(0xFFA855F7),
        title: 'No groups yet',
        description: 'Create groups like Work or Personal\nto organise your tasks.',
        actionLabel: 'Create first group',
        onAction: onAddGroup,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tasks.isNotEmpty) _ProgressHeader(tasks: tasks),
          for (final group in groups)
            GroupSection(
              key: ValueKey(group.id),
              group: group,
              tasks: tasks.where((t) => t.groupId == group.id).toList(),
            ),
          if (ungrouped.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Other',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: ungrouped.length,
              onReorder: (oldIndex, newIndex) =>
                  ref.read(tasksProvider.notifier).reorderGroup(null, oldIndex, newIndex),
              itemBuilder: (_, i) => TaskCard(
                key: ValueKey(ungrouped[i].id),
                task: ungrouped[i],
                index: i,
              ),
            ),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.tasks});

  final List tasks;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => (t as dynamic).isDone == true).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : done / total;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done of $total tasks done',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: context.trackSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartSessionBar extends ConsumerStatefulWidget {
  const _StartSessionBar({required this.pendingCount});

  final int pendingCount;

  @override
  ConsumerState<_StartSessionBar> createState() => _StartSessionBarState();
}

class _StartSessionBarState extends ConsumerState<_StartSessionBar> {
  int _cycles = 1;
  static const _cycleOptions = [1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Repeat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              ..._cycleOptions.map((v) {
                final sel = v == _cycles;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _cycles = v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? cs.primary : context.chipSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${v}×',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              final pending = ref.read(pendingTasksProvider);
              final tasks = _cycles > 1
                  ? [for (var i = 0; i < _cycles; i++) ...pending]
                  : pending;
              ref.read(sessionProvider.notifier).start(
                tasks,
                cycleSize: _cycles > 1 ? pending.length : 0,
              );
              context.go('/session');
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              'Start session · ${widget.pendingCount} task${widget.pendingCount == 1 ? '' : 's'}',
            ),
            style: FilledButton.styleFrom(backgroundColor: cs.primary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ],
        ),
      ),
    );
  }
}
