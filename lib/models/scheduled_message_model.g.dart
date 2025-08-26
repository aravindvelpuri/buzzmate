// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduledMessageModelAdapter extends TypeAdapter<ScheduledMessageModel> {
  @override
  final int typeId = 4;

  @override
  ScheduledMessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduledMessageModel(
      id: fields[0] as String,
      senderId: fields[1] as String,
      recipientIds: (fields[2] as List).cast<String>(),
      content: fields[3] as String,
      type: fields[4] as String,
      scheduledTime: fields[5] as DateTime,
      isSent: fields[6] as bool,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledMessageModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.recipientIds)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.scheduledTime)
      ..writeByte(6)
      ..write(obj.isSent)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledMessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
