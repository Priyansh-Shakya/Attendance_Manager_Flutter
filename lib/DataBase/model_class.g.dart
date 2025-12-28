// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_class.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceDataAdapter extends TypeAdapter<AttendanceData> {
  @override
  final int typeId = 0;

  @override
  AttendanceData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceData(
      date: fields[0] as DateTime,
      isPresent: fields[1] as bool,
      classesPresent: (fields[2] as List?)?.cast<bool>(),
      sessionId: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.isPresent)
      ..writeByte(2)
      ..write(obj.classesPresent)
      ..writeByte(3)
      ..write(obj.sessionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionDataAdapter extends TypeAdapter<SessionData> {
  @override
  final int typeId = 1;

  @override
  SessionData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionData(
      sessionStart: fields[0] as DateTime,
      sessionEnd: fields[1] as DateTime,
      creationDate: fields[2] as DateTime,
      activeDaysPerWeek: fields[3] as int,
      targetAttendance: fields[4] as double,
      sessionName: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SessionData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.sessionStart)
      ..writeByte(1)
      ..write(obj.sessionEnd)
      ..writeByte(2)
      ..write(obj.creationDate)
      ..writeByte(3)
      ..write(obj.activeDaysPerWeek)
      ..writeByte(4)
      ..write(obj.targetAttendance)
      ..writeByte(5)
      ..write(obj.sessionName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
