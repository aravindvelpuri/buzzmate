import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'scheduled_message_model.g.dart';

@HiveType(typeId: 4)
class ScheduledMessageModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String senderId;
  
  @HiveField(2)
  final List<String> recipientIds;
  
  @HiveField(3)
  final String content;
  
  @HiveField(4)
  final String type;
  
  @HiveField(5)
  final DateTime scheduledTime;
  
  @HiveField(6)
  final bool isSent;
  
  @HiveField(7)
  final DateTime createdAt;

  ScheduledMessageModel({
    required this.id,
    required this.senderId,
    required this.recipientIds,
    required this.content,
    required this.type,
    required this.scheduledTime,
    this.isSent = false,
    required this.createdAt,
  });

  factory ScheduledMessageModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ScheduledMessageModel(
      id: id,
      senderId: data['senderId'],
      recipientIds: List<String>.from(data['recipientIds']),
      content: data['content'],
      type: data['type'] ?? 'text',
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      isSent: data['isSent'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientIds': recipientIds,
      'content': content,
      'type': type,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'isSent': isSent,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Add these missing methods
  factory ScheduledMessageModel.fromJson(Map<String, dynamic> json) {
    return ScheduledMessageModel(
      id: json['id'],
      senderId: json['senderId'],
      recipientIds: List<String>.from(json['recipientIds']),
      content: json['content'],
      type: json['type'] ?? 'text',
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(json['scheduledTime']),
      isSent: json['isSent'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientIds': recipientIds,
      'content': content,
      'type': type,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'isSent': isSent,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}