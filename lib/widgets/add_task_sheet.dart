import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../extensions.dart';
import '../models/task.dart';
import '../models/task_group.dart';
import '../providers/defaults_provider.dart';
import '../providers/groups_provider.dart';
import '../providers/tasks_provider.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key, this.task, this.initialGroupId});

  final Task? task;
  final String? initialGroupId;

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  late final TextEditingController _titleCtrl;
  late int _focusMinutes;
  late int _breakMinutes;
  String? _groupId;

  static const _focusOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90];
  static const _breakOptions = [0, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _titleCtrl.addListener(() => setState(() {}));
    if (t != null) {
      _focusMinutes = t.focusMinutes;
      _breakMinutes = t.breakMinutes;
      _groupId = t.groupId;
    } else {
      _focusMinutes = ref.read(defaultFocusProvider);
      _breakMinutes = ref.read(defaultBreakProvider);
      _groupId = widget.initialGroupId;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final notifier = ref.read(tasksProvider.notifier);
    if (widget.task == null) {
      notifier.add(Task(
        title: title,
        focusMinutes: _focusMinutes,
        breakMinutes: _breakMinutes,
        groupId: _groupId,
      ));
    } else {
      notifier.update(widget.task!.copyWith(
        title: title,
        focusMinutes: _focusMinutes,
        breakMinutes: _breakMinutes,
        groupId: _groupId,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = ref.watch(groupsProvider);
    final isValid = _titleCtrl.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.task == null ? 'New task' : 'Edit task',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              if (widget.task != null) ...[
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Delete task',
                  onPressed: () {
                    ref.read(tasksProvider.notifier).remove(widget.task!.id);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What do you want to work on?'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          _SectionLabel(label: 'Focus time'),
          const SizedBox(height: 8),
          _ChipRow(
            options: _focusOptions,
            selected: _focusMinutes,
            label: (v) => '${v}m',
            onSelected: (v) => setState(() => _focusMinutes = v),
          ),
          const SizedBox(height: 16),
          _SectionLabel(label: 'Break after'),
          const SizedBox(height: 8),
          _ChipRow(
            options: _breakOptions,
            selected: _breakMinutes,
            label: (v) => v == 0 ? 'None' : '${v}m',
            onSelected: (v) => setState(() => _breakMinutes = v),
          ),
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel(label: 'Group'),
            const SizedBox(height: 8),
            _GroupPicker(
              groups: groups,
              selectedId: _groupId,
              onSelected: (id) => setState(() => _groupId = id),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isValid ? _save : null,
            style: FilledButton.styleFrom(backgroundColor: cs.primary),
            child: Text(widget.task == null ? 'Add task' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}

class _GroupPicker extends StatelessWidget {
  const _GroupPicker({
    required this.groups,
    required this.selectedId,
    required this.onSelected,
  });

  final List<TaskGroup> groups;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _GroupChip(
          label: 'None',
          color: cs.onSurface.withValues(alpha: 0.25),
          isSelected: selectedId == null,
          onTap: () => onSelected(null),
        ),
        for (final g in groups)
          _GroupChip(
            label: g.name,
            color: g.color,
            isSelected: selectedId == g.id,
            onTap: () => onSelected(g.id),
          ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : context.chipSurface,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
      );
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<int> options;
  final int selected;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onSelected(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : context.chipSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label(v),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
