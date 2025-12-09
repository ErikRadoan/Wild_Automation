import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'window_target.g.dart';

/// Represents a target application window
@HiveType(typeId: 2)
class WindowTarget extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? executablePath;

  @HiveField(3)
  final String? windowTitle;

  @HiveField(4)
  final String? processName;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final WindowMatchType matchType;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  const WindowTarget({
    required this.id,
    required this.name,
    this.executablePath,
    this.windowTitle,
    this.processName,
    this.description,
    required this.matchType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WindowTarget.create({
    required String id,
    required String name,
    String? executablePath,
    String? windowTitle,
    String? processName,
    String? description,
    WindowMatchType matchType = WindowMatchType.title,
  }) {
    final now = DateTime.now();
    return WindowTarget(
      id: id,
      name: name,
      executablePath: executablePath,
      windowTitle: windowTitle,
      processName: processName,
      description: description,
      matchType: matchType,
      createdAt: now,
      updatedAt: now,
    );
  }

  WindowTarget copyWith({
    String? name,
    String? executablePath,
    String? windowTitle,
    String? processName,
    String? description,
    WindowMatchType? matchType,
  }) {
    return WindowTarget(
      id: id,
      name: name ?? this.name,
      executablePath: executablePath ?? this.executablePath,
      windowTitle: windowTitle ?? this.windowTitle,
      processName: processName ?? this.processName,
      description: description ?? this.description,
      matchType: matchType ?? this.matchType,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        executablePath,
        windowTitle,
        processName,
        matchType,
      ];

  @override
  String toString() => 'WindowTarget(name: $name, matchType: $matchType)';
}

/// How to match a window
@HiveType(typeId: 3)
enum WindowMatchType {
  @HiveField(0)
  title,

  @HiveField(1)
  processName,

  @HiveField(2)
  executablePath,

  @HiveField(3)
  titleContains,
}

