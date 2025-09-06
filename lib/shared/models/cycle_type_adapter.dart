import 'package:hive/hive.dart';
import './cycle_type.dart';

// CycleType枚举的Hive适配器
class CycleTypeAdapter extends TypeAdapter<CycleType> {
  @override
  final typeId = 2; // 确保这个ID是唯一的，不与其他适配器冲突

  @override
  CycleType read(BinaryReader reader) {
    return CycleType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, CycleType obj) {
    writer.writeByte(obj.index);
  }
}