import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/add_group_sheet.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_card.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupsProvider).where((g) => g.id == groupId).firstOrNull;

    if (group == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/groups'));
      return const Scaffold(body: SizedBox.shrink());
    }

    final tasks = ref.watch(tasksProvider).where((t) => t.groupId == groupId).toList();
    final doneCount = tasks.where((t) => t.isDone).length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/groups'),
        ),
        title: Text(group.name),
        actions: [
          if (doneCount > 0)
            TextButton.icon(
              onPressed: () => ref.read(tasksProvider.notifier).resetDone(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit group',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => AddGroupSheet(group: group),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: tasks.isEmpty
          ? _EmptyState(onAdd: () => _openAddTask(context, groupId: groupId))
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) =>
                  ref.read(tasksProvider.notifier).reorderGroup(groupId, oldIndex, newIndex),
              itemBuilder: (_, i) => TaskCard(
                key: ValueKey(tasks[i].id),
                task: tasks[i],
                index: i,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTask(context, groupId: groupId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddTask(BuildContext context, {required String groupId}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => AddTaskSheet(initialGroupId: groupId),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

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
              child: Icon(Icons.checklist_rounded, size: 36, color: cs.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tasks yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add tasks to this group.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add first task'),
            ),
          ],
        ),
      ),
    );
  }
}
