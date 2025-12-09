import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'project.g.dart';

/// Represents a WILD Automate project
@HiveType(typeId: 5)
class Project extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastOpenedAt;

  const Project({
    required this.id,
    required this.name,
    required this.path,
    this.description,
    required this.createdAt,
    required this.lastOpenedAt,
  });

  factory Project.create({
    required String id,
    required String name,
    required String path,
    String? description,
  }) {
    final now = DateTime.now();
    return Project(
      id: id,
      name: name,
      path: path,
      description: description,
      createdAt: now,
      lastOpenedAt: now,
    );
  }

  Project copyWith({
    String? name,
    String? path,
    String? description,
    DateTime? lastOpenedAt,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      path: path ?? this.path,
      description: description ?? this.description,
      createdAt: createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, path, description, createdAt, lastOpenedAt];

  @override
  String toString() => 'Project(name: $name, path: $path)';
}

