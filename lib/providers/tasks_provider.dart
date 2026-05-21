import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier() : super([]) {
    _load();
  }

  static const _key = 'tasks_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((t) => t.toJson()).toList()),
    );
  }

  void add(Task task) {
    state = [...state, task];
    _save();
  }

  void update(Task task) {
    state = [for (final t in state) t.id == task.id ? task : t];
    _save();
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
    _save();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    _save();
  }

  void resetDone() {
    state = [for (final t in state) t.copyWith(isDone: false)];
    _save();
  }

  void markDone(String id) {
    state = [
      for (final t in state) t.id == id ? t.copyWith(isDone: true) : t,
    ];
    _save();
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>(
  (ref) => TasksNotifier(),
);

final pendingTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(tasksProvider).where((t) => !t.isDone).toList();
});
