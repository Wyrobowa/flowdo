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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group?.name ?? '');
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
      notifier.add(TaskGroup(name: name));
    } else {
      notifier.update(widget.group!.copyWith(name: name));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  icon: Icon(Icons.delete_outline, color: cs.error),
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
          const SizedBox(height: 28),
          FilledButton(
            onPressed: isValid ? _save : null,
            child: Text(widget.group == null ? 'Create group' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
