import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/tasks_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(width: 8),
        ],
      ),
      body: tasks.isEmpty
          ? _EmptyState(onAdd: () => _openAddSheet(context))
          : Column(
              children: [
                if (tasks.isNotEmpty) _ProgressHeader(tasks: tasks),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: tasks.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(tasksProvider.notifier)
                          .reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (_, i) => TaskCard(
                      key: ValueKey(tasks[i].id),
                      task: tasks[i],
                      index: i,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
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

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddTaskSheet(),
    );
  }
}

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
  const _StartSessionBar({
    required this.pendingCount,
    required this.onStart,
  });

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
