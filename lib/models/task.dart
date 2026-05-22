import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final int focusSeconds;
  final int breakSeconds;
  final bool isDone;
  final String notes;

  Task({
    String? id,
    required this.title,
    required this.focusSeconds,
    this.breakSeconds = 300,
    this.isDone = false,
    this.notes = '',
  }) : id = id ?? const Uuid().v4();

  Task copyWith({
    String? title,
    int? focusSeconds,
    int? breakSeconds,
    bool? isDone,
    String? notes,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        focusSeconds: focusSeconds ?? this.focusSeconds,
        breakSeconds: breakSeconds ?? this.breakSeconds,
        isDone: isDone ?? this.isDone,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'focusSeconds': focusSeconds,
        'breakSeconds': breakSeconds,
        'isDone': isDone,
        'notes': notes,
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
        notes: (json['notes'] as String?) ?? '',
      );
}
