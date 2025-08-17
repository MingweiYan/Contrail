import 'package:hive/hive.dart';
import 'habit.dart';

class GoalTypeAdapter extends TypeAdapter<GoalType> {
  @override
  final int typeId = 1; // 确保这个ID是唯一的

  @override
  GoalType read(BinaryReader reader) {
    return GoalType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, GoalType obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}