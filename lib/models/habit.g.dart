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
      totalDuration: fields[3] as Duration,
      currentDays: fields[4] as int,
      targetDays: fields[6] as int?,
      goalType: fields[7] as GoalType,
      imagePath: fields[9] as String?,
      cycleType: fields[10] as CycleType?,
      icon: fields[15] as String?,
      trackTime: fields[11] as bool,
      trackingDurations: (fields[13] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as DateTime, (v as List).cast<Duration>())),
      dailyCompletionStatus: (fields[14] as Map?)?.cast<DateTime, bool>(),
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
      ..writeByte(9)
      ..write(obj.imagePath)
      ..writeByte(10)
      ..write(obj.cycleType)
      ..writeByte(15)
      ..write(obj.icon)
      ..writeByte(11)
      ..write(obj.trackTime)
      ..writeByte(3)
      ..write(obj.totalDuration)
      ..writeByte(4)
      ..write(obj.currentDays)
      ..writeByte(6)
      ..write(obj.targetDays)
      ..writeByte(7)
      ..write(obj.goalType)
      ..writeByte(13)
      ..write(obj.trackingDurations)
      ..writeByte(14)
      ..write(obj.dailyCompletionStatus);
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
