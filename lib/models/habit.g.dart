// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      currentCount: fields[2] as int,
      currentDays: fields[4] as int,
      targetCount: fields[5] as int?,
      targetDays: fields[6] as int?,
      goalType: fields[7] as GoalType,
      imagePath: fields[9] as String?,
      cycleType: fields[10] as CycleType?,
      cycleConfig: fields[11] as String?,
      trackTime: fields[12] as bool,
      trackingRecords: (fields[8] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as DateTime, (v as List).cast<Duration>())),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.currentCount)
      ..writeByte(4)
      ..write(obj.currentDays)
      ..writeByte(5)
      ..write(obj.targetCount)
      ..writeByte(6)
      ..write(obj.targetDays)
      ..writeByte(7)
      ..write(obj.goalType)
      ..writeByte(8)
      ..write(obj.trackingRecords)
      ..writeByte(9)
      ..write(obj.imagePath)
      ..writeByte(10)
      ..write(obj.cycleType)
      ..writeByte(11)
      ..write(obj.cycleConfig)
      ..writeByte(12)
      ..write(obj.trackTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
