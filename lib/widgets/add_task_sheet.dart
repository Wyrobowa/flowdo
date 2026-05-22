import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/defaults_provider.dart';
import '../providers/tasks_provider.dart';
import 'duration_picker.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key, this.task});
  final Task? task;

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  late final TextEditingController _titleCtrl;
  late Duration _focusDuration;
  late Duration _breakDuration;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _titleCtrl.addListener(() => setState(() {}));
    if (t != null) {
      _focusDuration = Duration(seconds: t.focusSeconds);
      _breakDuration = Duration(seconds: t.breakSeconds);
    } else {
      _focusDuration = Duration(seconds: ref.read(defaultFocusProvider));
      _breakDuration = Duration(seconds: ref.read(defaultBreakProvider));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final focusSecs = _focusDuration.inSeconds.clamp(30, 86399);
    final breakSecs = _breakDuration.inSeconds.clamp(0, 86399);
    final notifier = ref.read(tasksProvider.notifier);
    if (widget.task == null) {
      notifier.add(Task(
        title: title,
        focusSeconds: focusSecs,
        breakSeconds: breakSecs,
      ));
    } else {
      notifier.update(widget.task!.copyWith(
        title: title,
        focusSeconds: focusSecs,
        breakSeconds: breakSecs,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isValid = _titleCtrl.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
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
              const SizedBox(height: 24),
              _SectionLabel(label: 'Focus time'),
              const SizedBox(height: 8),
              DurationPicker(
                initial: _focusDuration,
                onChanged: (d) => setState(() => _focusDuration = d),
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Break after'),
              const SizedBox(height: 8),
              DurationPicker(
                initial: _breakDuration,
                onChanged: (d) => setState(() => _breakDuration = d),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isValid ? _save : null,
                style: FilledButton.styleFrom(backgroundColor: cs.primary),
                child: Text(widget.task == null ? 'Add task' : 'Save changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
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
