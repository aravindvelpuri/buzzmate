import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 2)
class MessageModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String chatId;
  
  @HiveField(2)
  final String senderId;
  
  @HiveField(3)
  final String content;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final String type;
  
  @HiveField(6)
  final bool read;
  
  @HiveField(7)
  final Map<String, List<String>> reactions;
  
  @HiveField(8)
  final bool edited;
  
  @HiveField(9)
  final DateTime? editedAt;
  
  @HiveField(10)
  final DateTime? expireTime;
  
  @HiveField(11)
  final String? replyToMessageId;
  
  @HiveField(12)
  final MessageModel? replyToMessage;
  
  @HiveField(13)
  final String? forwardedFrom;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.read = false,
    this.reactions = const {},
    this.edited = false,
    this.editedAt,
    this.expireTime,
    this.replyToMessageId,
    this.replyToMessage,
    this.forwardedFrom,
  });

  factory MessageModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      chatId: data['chatId'],
      senderId: data['senderId'],
      content: data['content'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'text',
      read: data['read'] ?? false,
      reactions: (data['reactions'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).cast<String>(),
        ),
      ) ?? {},
      edited: data['edited'] ?? false,
      editedAt: data['editedAt'] != null ? (data['editedAt'] as Timestamp).toDate() : null,
      expireTime: data['expireTime'] != null ? (data['expireTime'] as Timestamp).toDate() : null,
      replyToMessageId: data['replyToMessageId'],
      forwardedFrom: data['forwardedFrom'],
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      type: json['type'] ?? 'text',
      read: json['read'] ?? false,
      reactions: Map<String, List<String>>.from(json['reactions'] ?? {}),
      edited: json['edited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['editedAt']) : null,
      expireTime: json['expireTime'] != null ? DateTime.fromMillisecondsSinceEpoch(json['expireTime']) : null,
      replyToMessageId: json['replyToMessageId'],
      replyToMessage: json['replyToMessage'] != null ? MessageModel.fromJson(json['replyToMessage']) : null,
      forwardedFrom: json['forwardedFrom'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'read': read,
      'reactions': reactions,
      'edited': edited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'expireTime': expireTime != null ? Timestamp.fromDate(expireTime!) : null,
      'replyToMessageId': replyToMessageId,
      'forwardedFrom': forwardedFrom,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'read': read,
      'reactions': reactions,
      'edited': edited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'expireTime': expireTime?.millisecondsSinceEpoch,
      'replyToMessageId': replyToMessageId,
      'replyToMessage': replyToMessage?.toJson(),
      'forwardedFrom': forwardedFrom,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    String? type,
    bool? read,
    Map<String, List<String>>? reactions,
    bool? edited,
    DateTime? editedAt,
    DateTime? expireTime,
    String? replyToMessageId,
    MessageModel? replyToMessage,
    String? forwardedFrom,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      read: read ?? this.read,
      reactions: reactions ?? this.reactions,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      expireTime: expireTime ?? this.expireTime,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
    );
  }
}