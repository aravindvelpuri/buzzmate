import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'group_model.g.dart';

@HiveType(typeId: 3)
class GroupModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String avatarUrl;
  
  @HiveField(4)
  final List<String> participants;
  
  @HiveField(5)
  final List<String> admins;
  
  @HiveField(6)
  final String createdBy;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarUrl,
    required this.participants,
    required this.admins,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromFirestore(String id, Map<String, dynamic> data) {
    return GroupModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'participants': participants,
      'admins': admins,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}