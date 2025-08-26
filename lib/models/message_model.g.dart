// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 2;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String,
      chatId: fields[1] as String,
      senderId: fields[2] as String,
      content: fields[3] as String,
      timestamp: fields[4] as DateTime,
      type: fields[5] as String,
      read: fields[6] as bool,
      reactions: (fields[7] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      edited: fields[8] as bool,
      editedAt: fields[9] as DateTime?,
      expireTime: fields[10] as DateTime?,
      replyToMessageId: fields[11] as String?,
      replyToMessage: fields[12] as MessageModel?,
      forwardedFrom: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.read)
      ..writeByte(7)
      ..write(obj.reactions)
      ..writeByte(8)
      ..write(obj.edited)
      ..writeByte(9)
      ..write(obj.editedAt)
      ..writeByte(10)
      ..write(obj.expireTime)
      ..writeByte(11)
      ..write(obj.replyToMessageId)
      ..writeByte(12)
      ..write(obj.replyToMessage)
      ..writeByte(13)
      ..write(obj.forwardedFrom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
