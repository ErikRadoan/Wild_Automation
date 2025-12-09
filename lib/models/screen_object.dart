import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'screen_object.g.dart';

/// Represents a screen object - either a point or a rectangular area
@HiveType(typeId: 0)
class ScreenObject extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ScreenObjectType type;

  @HiveField(3)
  final int x;

  @HiveField(4)
  final int y;

  @HiveField(5)
  final int? x2;

  @HiveField(6)
  final int? y2;

  @HiveField(7)
  final String? description;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  const ScreenObject({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    this.x2,
    this.y2,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a point object
  factory ScreenObject.point({
    required String id,
    required String name,
    required int x,
    required int y,
    String? description,
  }) {
    final now = DateTime.now();
    return ScreenObject(
      id: id,
      name: name,
      type: ScreenObjectType.point,
      x: x,
      y: y,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a rectangle object with two points
  factory ScreenObject.rectangle({
    required String id,
    required String name,
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    String? description,
  }) {
    final now = DateTime.now();
    return ScreenObject(
      id: id,
      name: name,
      type: ScreenObjectType.rectangle,
      x: x1,
      y: y1,
      x2: x2,
      y2: y2,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if this is a point
  bool get isPoint => type == ScreenObjectType.point;

  /// Check if this is a rectangle
  bool get isRectangle => type == ScreenObjectType.rectangle;

  /// Get width (for rectangles)
  int get width => isRectangle ? (x2! - x).abs() : 0;

  /// Get height (for rectangles)
  int get height => isRectangle ? (y2! - y).abs() : 0;

  /// Get the center point of the object
  Point get center {
    if (isPoint) {
      return Point(x, y);
    }
    return Point((x + x2!) ~/ 2, (y + y2!) ~/ 2);
  }

  /// Copy with new values
  ScreenObject copyWith({
    String? name,
    ScreenObjectType? type,
    int? x,
    int? y,
    int? x2,
    int? y2,
    String? description,
  }) {
    return ScreenObject(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, type, x, y, x2, y2, description];

  @override
  String toString() {
    if (isPoint) {
      return 'ScreenObject(name: $name, point: ($x, $y))';
    }
    return 'ScreenObject(name: $name, rect: ($x, $y) to ($x2, $y2))';
  }
}

/// Type of screen object
@HiveType(typeId: 1)
enum ScreenObjectType {
  @HiveField(0)
  point,

  @HiveField(1)
  rectangle,
}

/// Simple point representation
class Point extends Equatable {
  final int x;
  final int y;

  const Point(this.x, this.y);

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => '($x, $y)';
}

