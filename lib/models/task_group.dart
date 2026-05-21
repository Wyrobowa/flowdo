import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const groupColors = [
  Color(0xFFE05A2B),
  Color(0xFF3B82F6),
  Color(0xFF22C55E),
  Color(0xFFA855F7),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
];

class TaskGroup {
  final String id;
  final String name;
  final int colorIndex;

  TaskGroup({
    String? id,
    required this.name,
    this.colorIndex = 0,
  }) : id = id ?? const Uuid().v4();

  Color get color => groupColors[colorIndex % groupColors.length];

  TaskGroup copyWith({String? name, int? colorIndex}) => TaskGroup(
        id: id,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
      };

  factory TaskGroup.fromJson(Map<String, dynamic> json) => TaskGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        colorIndex: (json['colorIndex'] as int?) ?? 0,
      );
}
