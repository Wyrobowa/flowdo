import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final int focusSeconds;
  final int breakSeconds;
  final bool isDone;

  Task({
    String? id,
    required this.title,
    required this.focusSeconds,
    this.breakSeconds = 300,
    this.isDone = false,
  }) : id = id ?? const Uuid().v4();

  Task copyWith({
    String? title,
    int? focusSeconds,
    int? breakSeconds,
    bool? isDone,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        focusSeconds: focusSeconds ?? this.focusSeconds,
        breakSeconds: breakSeconds ?? this.breakSeconds,
        isDone: isDone ?? this.isDone,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'focusSeconds': focusSeconds,
        'breakSeconds': breakSeconds,
        'isDone': isDone,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        // Migrate old minute-based saves to seconds
        focusSeconds: json['focusSeconds'] as int? ??
            ((json['focusMinutes'] as int?) ?? 25) * 60,
        breakSeconds: json['breakSeconds'] as int? ??
            ((json['breakMinutes'] as int?) ?? 5) * 60,
        isDone: (json['isDone'] as bool?) ?? false,
      );
}
