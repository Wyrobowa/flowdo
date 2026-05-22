import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_group.dart';
import '../providers/groups_provider.dart';
import '../providers/tasks_provider.dart';

class AddGroupSheet extends ConsumerStatefulWidget {
  const AddGroupSheet({super.key, this.group});

  final TaskGroup? group;

  @override
  ConsumerState<AddGroupSheet> createState() => _AddGroupSheetState();
}

class _AddGroupSheetState extends ConsumerState<AddGroupSheet> {
  late final TextEditingController _nameCtrl;
  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _colorIndex = g?.colorIndex ?? 0;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: const Text('Its tasks will become ungrouped.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(tasksProvider.notifier).ungroupByGroupId(widget.group!.id);
      ref.read(groupsProvider.notifier).remove(widget.group!.id);
      Navigator.of(context).pop();
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(groupsProvider.notifier);
    if (widget.group == null) {
      notifier.add(TaskGroup(name: name, colorIndex: _colorIndex));
    } else {
      notifier.update(widget.group!.copyWith(name: name, colorIndex: _colorIndex));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nameCtrl.text.trim().isNotEmpty;

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
                widget.group == null ? 'New group' : 'Edit group',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              if (widget.group != null) ...[
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: 'Delete group',
                  onPressed: _confirmDelete,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Group name'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          Text(
            'COLOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(groupColors.length, (i) {
              final selected = i == _colorIndex;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: groupColors[i],
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: groupColors[i].withValues(alpha: 0.45),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: isValid ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: groupColors[_colorIndex],
            ),
            child: Text(widget.group == null ? 'Create group' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
