import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_group.dart';

class GroupsNotifier extends StateNotifier<List<TaskGroup>> {
  GroupsNotifier() : super([]) {
    _load();
  }

  static const _key = 'groups_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      state = (jsonDecode(raw) as List)
          .map((e) => TaskGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.map((g) => g.toJson()).toList()));
  }

  void add(TaskGroup group) {
    state = [...state, group];
    _save();
  }

  void update(TaskGroup group) {
    state = [for (final g in state) g.id == group.id ? group : g];
    _save();
  }

  void remove(String id) {
    state = state.where((g) => g.id != id).toList();
    _save();
  }
}

final groupsProvider =
    StateNotifierProvider<GroupsNotifier, List<TaskGroup>>(
  (ref) => GroupsNotifier(),
);
