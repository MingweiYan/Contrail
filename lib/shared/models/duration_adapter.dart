import 'package:hive/hive.dart';

class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 3; // 为Duration类型分配一个唯一的typeId

  @override
  Duration read(BinaryReader reader) {
    final microseconds = reader.readInt();
    return Duration(microseconds: microseconds);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}
