import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'chat_model.g.dart';

@HiveType(typeId: 1)
class ChatModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final List<String> participants;
  
  @HiveField(2)
  final String lastMessage;
  
  @HiveField(3)
  final DateTime lastMessageTime;
  
  @HiveField(4)
  final int unreadCount;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime updatedAt;
  
  @HiveField(7)
  final bool isGroup;
  
  @HiveField(8)
  final String? name;
  
  @HiveField(9)
  final String? description;
  
  @HiveField(10)
  final String? avatarUrl;
  
  @HiveField(11)
  final List<String>? admins;
  
  @HiveField(12)
  final String? createdBy;
  
  @HiveField(13)
  final List<String> typingUsers;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.isGroup = false,
    this.name,
    this.description,
    this.avatarUrl,
    this.admins,
    this.createdBy,
    this.typingUsers = const [],
  });

  factory ChatModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatModel(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: data['isGroup'] ?? false,
      name: data['name'],
      description: data['description'],
      avatarUrl: data['avatarUrl'],
      admins: data['admins'] != null ? List<String>.from(data['admins']) : null,
      createdBy: data['createdBy'],
      typingUsers: List<String>.from(data['typingUsers'] ?? []),
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      participants: List<String>.from(json['participants']),
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime']),
      unreadCount: json['unreadCount'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      isGroup: json['isGroup'] ?? false,
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatarUrl'],
      admins: json['admins'] != null ? List<String>.from(json['admins']) : null,
      createdBy: json['createdBy'],
      typingUsers: List<String>.from(json['typingUsers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'admins': admins,
      'createdBy': createdBy,
      'typingUsers': typingUsers,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isGroup': isGroup,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'admins': admins,
      'createdBy': createdBy,
      'typingUsers': typingUsers,
    };
  }
}