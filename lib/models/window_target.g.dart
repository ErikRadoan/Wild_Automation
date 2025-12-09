// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_target.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WindowTargetAdapter extends TypeAdapter<WindowTarget> {
  @override
  final int typeId = 2;

  @override
  WindowTarget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WindowTarget(
      id: fields[0] as String,
      name: fields[1] as String,
      executablePath: fields[2] as String?,
      windowTitle: fields[3] as String?,
      processName: fields[4] as String?,
      description: fields[5] as String?,
      matchType: fields[6] as WindowMatchType,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WindowTarget obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.executablePath)
      ..writeByte(3)
      ..write(obj.windowTitle)
      ..writeByte(4)
      ..write(obj.processName)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.matchType)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowTargetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WindowMatchTypeAdapter extends TypeAdapter<WindowMatchType> {
  @override
  final int typeId = 3;

  @override
  WindowMatchType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WindowMatchType.title;
      case 1:
        return WindowMatchType.processName;
      case 2:
        return WindowMatchType.executablePath;
      case 3:
        return WindowMatchType.titleContains;
      default:
        return WindowMatchType.title;
    }
  }

  @override
  void write(BinaryWriter writer, WindowMatchType obj) {
    switch (obj) {
      case WindowMatchType.title:
        writer.writeByte(0);
        break;
      case WindowMatchType.processName:
        writer.writeByte(1);
        break;
      case WindowMatchType.executablePath:
        writer.writeByte(2);
        break;
      case WindowMatchType.titleContains:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowMatchTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
