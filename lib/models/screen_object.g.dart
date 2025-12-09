// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_object.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScreenObjectAdapter extends TypeAdapter<ScreenObject> {
  @override
  final int typeId = 0;

  @override
  ScreenObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScreenObject(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as ScreenObjectType,
      x: fields[3] as int,
      y: fields[4] as int,
      x2: fields[5] as int?,
      y2: fields[6] as int?,
      description: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScreenObject obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.x)
      ..writeByte(4)
      ..write(obj.y)
      ..writeByte(5)
      ..write(obj.x2)
      ..writeByte(6)
      ..write(obj.y2)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScreenObjectTypeAdapter extends TypeAdapter<ScreenObjectType> {
  @override
  final int typeId = 1;

  @override
  ScreenObjectType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScreenObjectType.point;
      case 1:
        return ScreenObjectType.rectangle;
      default:
        return ScreenObjectType.point;
    }
  }

  @override
  void write(BinaryWriter writer, ScreenObjectType obj) {
    switch (obj) {
      case ScreenObjectType.point:
        writer.writeByte(0);
        break;
      case ScreenObjectType.rectangle:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenObjectTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
