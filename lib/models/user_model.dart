import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String? bio;
  final String? profileImageUrl;
  final bool isPrivate;
  final bool emailVerified;
  final bool profileSetupComplete;
  final List<String> friends;
  final List<String> friendRequests;
  final List<String> pendingRequests;
  final int followers;
  final int following;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.bio,
    this.profileImageUrl,
    required this.isPrivate,
    required this.emailVerified,
    required this.profileSetupComplete,
    required this.friends,
    required this.friendRequests,
    required this.pendingRequests,
    required this.followers,
    required this.following,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      username: data['username'] ?? 'Unknown',
      fullName: data['fullName'] ?? '',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      isPrivate: data['isPrivate'] ?? false,
      emailVerified: data['emailVerified'] ?? false,
      profileSetupComplete: data['profileSetupComplete'] ?? false,
      friends: List<String>.from(data['friends'] ?? []),
      friendRequests: List<String>.from(data['friendRequests'] ?? []),
      pendingRequests: List<String>.from(data['pendingRequests'] ?? []),
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'fullName': fullName,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'isPrivate': isPrivate,
      'emailVerified': emailVerified,
      'profileSetupComplete': profileSetupComplete,
      'friends': friends,
      'friendRequests': friendRequests,
      'pendingRequests': pendingRequests,
      'followers': followers,
      'following': following,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}