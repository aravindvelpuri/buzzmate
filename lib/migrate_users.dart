import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateExistingUsers() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  try {
    // Get all existing users
    final QuerySnapshot users = await firestore.collection('users').get();
    
    // Batch update all users
    final WriteBatch batch = firestore.batch();
    
    for (final DocumentSnapshot userDoc in users.docs) {
      final Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      
      // ✅ Fix: Explicit type for updates
      final Map<String, dynamic> updates = {};
      
      if (!data.containsKey('friends')) {
        updates['friends'] = [];
      }
      if (!data.containsKey('friendRequests')) {
        updates['friendRequests'] = [];
      }
      if (!data.containsKey('pendingRequests')) {
        updates['pendingRequests'] = [];
      }
      if (!data.containsKey('followers')) {
        updates['followers'] = 0;
      }
      if (!data.containsKey('following')) {
        updates['following'] = 0;
      }
      if (!data.containsKey('createdAt')) {
        updates['createdAt'] = Timestamp.now();
      }
      if (!data.containsKey('bio')) {
        updates['bio'] = '';
      }
      if (!data.containsKey('isPrivate')) {
        updates['isPrivate'] = false;
      }
      
      if (updates.isNotEmpty) {
        batch.update(userDoc.reference, updates);
      }
    }
    
    // Commit the batch update
    await batch.commit();
    print('Migration completed successfully'); // 🔔 Consider replacing with logger
  } catch (e) {
    print('Migration failed: $e'); // 🔔 Consider replacing with logger
  }
}
