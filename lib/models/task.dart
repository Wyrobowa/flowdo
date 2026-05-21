import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final int focusMinutes;
  final int breakMinutes;
  final bool isDone;
  final String? groupId;

  Task({
    String? id,
    required this.title,
    required this.focusMinutes,
    this.breakMinutes = 5,
    this.isDone = false,
    this.groupId,
  }) : id = id ?? const Uuid().v4();

  // Sentinel lets callers explicitly pass null to clear groupId.
  static const _unset = Object();

  Task copyWith({
    String? title,
    int? focusMinutes,
    int? breakMinutes,
    bool? isDone,
    Object? groupId = _unset,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
        isDone: isDone ?? this.isDone,
        groupId: identical(groupId, _unset) ? this.groupId : groupId as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'focusMinutes': focusMinutes,
        'breakMinutes': breakMinutes,
        'isDone': isDone,
        'groupId': groupId,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        focusMinutes: json['focusMinutes'] as int,
        breakMinutes: (json['breakMinutes'] as int?) ?? 5,
        isDone: (json['isDone'] as bool?) ?? false,
        groupId: json['groupId'] as String?,
      );
}
