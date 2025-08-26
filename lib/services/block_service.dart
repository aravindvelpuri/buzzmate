import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('loggedInUser');
  }

  Future<void> blockUser(String blockedUserId) async {
    if (_currentUserId == null) return;
    
    await _firestore.collection('users').doc(_currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    });
  }

  Future<void> unblockUser(String blockedUserId) async {
    if (_currentUserId == null) return;
    
    await _firestore.collection('users').doc(_currentUserId).update({
      'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
    });
  }

  Future<bool> isUserBlocked(String otherUserId) async {
    if (_currentUserId == null) return false;
    
    final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
    if (!userDoc.exists) return false;
    
    final blockedUsers = List<String>.from(userDoc.data()?['blockedUsers'] ?? []);
    return blockedUsers.contains(otherUserId);
  }

  Future<bool> isBlockedByUser(String otherUserId) async {
    if (_currentUserId == null) return false;
    
    final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
    if (!otherUserDoc.exists) return false;
    
    final blockedUsers = List<String>.from(otherUserDoc.data()?['blockedUsers'] ?? []);
    return blockedUsers.contains(_currentUserId);
  }

  Future<List<String>> getBlockedUsers() async {
    if (_currentUserId == null) return [];
    
    final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
    if (!userDoc.exists) return [];
    
    return List<String>.from(userDoc.data()?['blockedUsers'] ?? []);
  }
}