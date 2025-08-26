import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart'; // 👈 animation package
import '../../theme/colors.dart';

class FriendRequestScreen extends StatefulWidget {
  final String userId;

  const FriendRequestScreen({super.key, required this.userId});

  @override
  State<FriendRequestScreen> createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      final List requestIds = userData['friendRequests'] ?? [];

      if (requestIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final requests = await Future.wait(
        requestIds.map((id) async {
          final userDoc = await _firestore.collection('users').doc(id).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            return {
              'id': id,
              'username': userData['username'] ?? 'Unknown',
              'fullName': userData['fullName'] ?? '',
              'profileImageUrl': userData['profileImageUrl'] ?? '',
            };
          }
          return {
            'id': id,
            'username': 'Unknown',
            'fullName': '',
            'profileImageUrl': '',
          };
        }),
      );

      setState(() {
        _requests = requests.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(String requesterId) async {
    try {
      final batch = _firestore.batch();
      
      // Update current user's friends and remove from requests
      final currentUserRef = _firestore.collection('users').doc(widget.userId);
      batch.update(currentUserRef, {
        'friends': FieldValue.arrayUnion([requesterId]),
        'friendRequests': FieldValue.arrayRemove([requesterId]),
        'followers': FieldValue.increment(1),
      });

      // Update requester's friends and remove from pending
      final requesterRef = _firestore.collection('users').doc(requesterId);
      batch.update(requesterRef, {
        'friends': FieldValue.arrayUnion([widget.userId]),
        'pendingRequests': FieldValue.arrayRemove([widget.userId]),
        'following': FieldValue.increment(1),
      });

      await batch.commit();
      
      setState(() {
        _requests.removeWhere((request) => request['id'] == requesterId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept request')),
        );
      }
    }
  }

  Future<void> _declineRequest(String requesterId) async {
    try {
      final batch = _firestore.batch();
      
      // Remove from current user's requests
      final currentUserRef = _firestore.collection('users').doc(widget.userId);
      batch.update(currentUserRef, {
        'friendRequests': FieldValue.arrayRemove([requesterId]),
      });

      // Remove from requester's pending
      final requesterRef = _firestore.collection('users').doc(requesterId);
      batch.update(requesterRef, {
        'pendingRequests': FieldValue.arrayRemove([widget.userId]),
      });

      await batch.commit();
      
      setState(() {
        _requests.removeWhere((request) => request['id'] == requesterId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to decline request')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: true, // 👈 keeps back button if needed
          elevation: 4,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20), // 👈 rounded bottom
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.group_add, size: 26, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                "Friend Requests",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              if (_requests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_requests.length}", // 👈 number of requests
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(
              child: Text(
                "No friend requests",
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: request['profileImageUrl'].isNotEmpty
                            ? CachedNetworkImageProvider(
                                request['profileImageUrl'],
                              )
                            : null,
                        child: request['profileImageUrl'].isEmpty
                            ? const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 30,
                              )
                            : null,
                      ),
                      title: Text(
                        request['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        request['fullName'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => _acceptRequest(request['id']),
                            child: const Icon(Icons.check, size: 20),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => _declineRequest(request['id']),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
