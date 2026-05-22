import 'package:uuid/uuid.dart';

class TaskGroup {
  final String id;
  final String name;

  TaskGroup({String? id, required this.name}) : id = id ?? const Uuid().v4();

  TaskGroup copyWith({String? name}) => TaskGroup(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory TaskGroup.fromJson(Map<String, dynamic> json) => TaskGroup(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
