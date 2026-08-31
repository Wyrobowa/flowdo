import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../extensions.dart';
import '../models/task.dart';
import '../providers/features_provider.dart';
import '../providers/session_provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/repeat_picker.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final pending = ref.watch(pendingTasksProvider);
    final doneCount = tasks.where((t) => t.isDone).length;
    final home = ref.watch(homeRouteProvider);

    return Scaffold(
      appBar: AppBar(
        // Nothing sits behind this screen when tasks are the only mode, so it
        // carries no back arrow then — and Settings has to be here either way,
        // since the mode picker it otherwise lives on may never be shown.
        automaticallyImplyLeading: false,
        leading: home == '/tasks'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => context.go(home),
              ),
        title: const Text('Tasks & breaks'),
        actions: [
          if (doneCount > 0)
            TextButton.icon(
              onPressed: () => ref.read(tasksProvider.notifier).resetDone(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: tasks.isEmpty
          ? _EmptyState(onAdd: () => _openAddTask(context))
          : Column(
              children: [
                _ProgressHeader(tasks: tasks),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTask(context),
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
      bottomSheet: pending.isEmpty ? null : const _StartSessionBar(),
    );
  }

  void _openAddTask(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const AddTaskSheet(),
      );
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.isDone).length;
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
  const _StartSessionBar();

  @override
  ConsumerState<_StartSessionBar> createState() => _StartSessionBarState();
}

class _StartSessionBarState extends ConsumerState<_StartSessionBar> {
  int _cycles = 1;

  /// What the button commits to: every pending task's focus and break, each
  /// pass of the list included. A break runs after the last task too, so no
  /// task is left out of the sum.
  Duration _total(List<Task> pending) => Duration(
        seconds: _cycles *
            pending.fold(0, (sum, t) => sum + t.focusSeconds + t.breakSeconds),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pending = ref.watch(pendingTasksProvider);
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
            // The picker grows downward when it opens; the label stays where
            // it is, boxed to the closed tile's height.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Repeat',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RepeatPicker(
                  initial: _cycles,
                  // A pass here is the whole pending list, so the session is
                  // max x pending.length long: six passes of ten tasks is
                  // already a day of focus.
                  max: 6,
                  compact: true,
                  onChanged: (v) => setState(() => _cycles = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              final tasks = _cycles > 1
                  ? [for (var i = 0; i < _cycles; i++) ...pending]
                  : pending;
              ref.read(sessionProvider.notifier).start(
                tasks,
                cycleSize: _cycles > 1 ? pending.length : 0,
                origin: '/tasks',
              );
              context.go('/session');
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              'Start session · ${pending.length} task${pending.length == 1 ? '' : 's'} · ${_total(pending).pretty}',
            ),
            style: FilledButton.styleFrom(backgroundColor: cs.primary),
          ),
        ],
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
              child: Icon(Icons.checklist_rounded, size: 36, color: cs.primary),
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
                color: cs.onSurface.withValues(alpha: 0.5),
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
