import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task.dart';
import '../models/task_group.dart';
import '../providers/groups_provider.dart';
import '../providers/session_provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/add_group_sheet.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/group_section.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final tasks = ref.watch(tasksProvider);
    final pending = ref.watch(pendingTasksProvider);
    final doneCount = tasks.where((t) => t.isDone).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flowdo'),
        actions: [
          if (doneCount > 0)
            TextButton.icon(
              onPressed: () => ref.read(tasksProvider.notifier).resetDone(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
            ),
          IconButton(
            onPressed: () => _openGroupSheet(context),
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New group',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: groups.isEmpty
          ? _FlatBody(tasks: tasks)
          : _GroupedBody(groups: groups, tasks: tasks),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskSheet(context),
        child: const Icon(Icons.add),
      ),
      bottomSheet: pending.isEmpty
          ? null
          : _StartSessionBar(
              pendingCount: pending.length,
              onStart: () {
                ref.read(sessionProvider.notifier).start(pending);
                context.go('/session');
              },
            ),
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

// ── Flat view (no groups) ────────────────────────────────────────────────────

class _FlatBody extends ConsumerWidget {
  const _FlatBody({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return _EmptyState(
        onAddTask: () => _openTaskSheet(context),
        onAddGroup: () => _openGroupSheet(context),
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

// ── Grouped view ─────────────────────────────────────────────────────────────

class _GroupedBody extends ConsumerWidget {
  const _GroupedBody({required this.groups, required this.tasks});

  final List<TaskGroup> groups;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ungrouped = tasks.where((t) => t.groupId == null).toList();

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

// ── Shared sub-widgets ────────────────────────────────────────────────────────

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
              backgroundColor: const Color(0xFFEDE9E4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartSessionBar extends StatelessWidget {
  const _StartSessionBar({required this.pendingCount, required this.onStart});

  final int pendingCount;
  final VoidCallback onStart;

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
      child: FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(
          'Start session · $pendingCount task${pendingCount == 1 ? '' : 's'}',
        ),
        style: FilledButton.styleFrom(backgroundColor: cs.primary),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTask, required this.onAddGroup});

  final VoidCallback onAddTask;
  final VoidCallback onAddGroup;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.format_list_bulleted_add,
                size: 36,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tasks yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add tasks with custom focus time\nand breaks, then start your flow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add),
              label: const Text('Add first task'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAddGroup,
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('Create a group'),
            ),
          ],
        ),
      ),
    );
  }
}
