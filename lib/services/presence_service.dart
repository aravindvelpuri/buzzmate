import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isOnline = false;
  String? _currentUserId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('loggedInUser');
    
    if (_currentUserId != null) {
      await setOnline();
      
      // Set up periodic last seen updates
      _setupPeriodicUpdates();
    }
  }

  Future<void> _setupPeriodicUpdates() async {
    // Update last seen every 30 seconds when app is active
    Future.delayed(const Duration(seconds: 30), () async {
      if (_isOnline && _currentUserId != null) {
        await _updateLastSeen();
        _setupPeriodicUpdates();
      }
    });
  }

  Future<void> setOnline() async {
    if (_isOnline || _currentUserId == null) return;
    
    await _firestore.collection('users').doc(_currentUserId).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    
    _isOnline = true;
  }

  Future<void> setOffline() async {
    if (!_isOnline || _currentUserId == null) return;
    
    await _firestore.collection('users').doc(_currentUserId).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    
    _isOnline = false;
  }

  Future<void> _updateLastSeen() async {
    if (_currentUserId == null) return;
    
    await _firestore.collection('users').doc(_currentUserId).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>> getUserPresence(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return {'isOnline': false, 'lastSeen': null};
      }
      
      final data = snapshot.data()!;
      return {
        'isOnline': data['isOnline'] ?? false,
        'lastSeen': data['lastSeen'] != null ? (data['lastSeen'] as Timestamp).toDate() : null,
      };
    });
  }
}