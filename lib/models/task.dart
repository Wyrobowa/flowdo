import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final int focusMinutes;
  final int breakMinutes;
  final bool isDone;

  Task({
    String? id,
    required this.title,
    required this.focusMinutes,
    this.breakMinutes = 5,
    this.isDone = false,
  }) : id = id ?? const Uuid().v4();

  Task copyWith({
    String? title,
    int? focusMinutes,
    int? breakMinutes,
    bool? isDone,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
        isDone: isDone ?? this.isDone,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'focusMinutes': focusMinutes,
        'breakMinutes': breakMinutes,
        'isDone': isDone,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        focusMinutes: json['focusMinutes'] as int,
        breakMinutes: (json['breakMinutes'] as int?) ?? 5,
        isDone: (json['isDone'] as bool?) ?? false,
      );
}
