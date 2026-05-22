import 'package:uuid/uuid.dart';

class SessionRecord {
  final String id;
  final DateTime completedAt;
  final int focusMinutes;
  final int taskCount;
  final List<String> taskTitles;

  SessionRecord({
    String? id,
    required this.completedAt,
    required this.focusMinutes,
    required this.taskCount,
    required this.taskTitles,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'completedAt': completedAt.toIso8601String(),
        'focusMinutes': focusMinutes,
        'taskCount': taskCount,
        'taskTitles': taskTitles,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        focusMinutes: json['focusMinutes'] as int,
        taskCount: json['taskCount'] as int,
        taskTitles: List<String>.from(json['taskTitles'] as List),
      );
}
