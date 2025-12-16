// GENERATED CODE - Manually written Hive adapter

part of 'inspiration.dart';

class InspirationAdapter extends TypeAdapter<Inspiration> {
  @override
  final int typeId = 0;

  @override
  Inspiration read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Inspiration(
      id: fields[0] as String,
      prompt: fields[1] as String,
      description: fields[2] as String,
      imageBytes: fields[3] as Uint8List,
      createdAt: fields[4] as DateTime,
      isHighQuality: fields[5] as bool,
      tags: (fields[6] as List).cast<String>(),
      isFavorite: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Inspiration obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.prompt)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageBytes)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isHighQuality)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspirationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
