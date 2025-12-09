import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'flow.g.dart';

/// Represents an automation flow with Python code
@HiveType(typeId: 4)
class Flow extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String pythonCode;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final List<String> tags;

  const Flow({
    required this.id,
    required this.name,
    required this.pythonCode,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  factory Flow.create({
    required String id,
    required String name,
    String pythonCode = '',
    String? description,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return Flow(
      id: id,
      name: name,
      pythonCode: pythonCode,
      description: description,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );
  }

  Flow copyWith({
    String? name,
    String? pythonCode,
    String? description,
    List<String>? tags,
  }) {
    return Flow(
      id: id,
      name: name ?? this.name,
      pythonCode: pythonCode ?? this.pythonCode,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [id, name, pythonCode, description, tags];

  @override
  String toString() => 'Flow(name: $name, lines: ${pythonCode.split('\n').length})';
}

