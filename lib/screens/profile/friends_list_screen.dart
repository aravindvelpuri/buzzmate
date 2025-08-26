import 'package:buzzmate/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_screen.dart';

class FriendsListScreen extends StatefulWidget {
  final String userId;

  const FriendsListScreen({super.key, required this.userId});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  List<String> _getListData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is List) {
      return List<String>.from(value);
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      final List<String> friendIds = _getListData(userData, 'friends');

      if (friendIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final friends = await Future.wait(
        friendIds.map((id) async {
          final friendDoc = await _firestore.collection('users').doc(id).get();
          if (friendDoc.exists) {
            final friendData = friendDoc.data()!;
            return {
              'id': id,
              'username': friendData['username'] ?? 'Unknown',
              'fullName': friendData['fullName'] ?? '',
              'profileImageUrl': friendData['profileImageUrl'] ?? '',
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
        _friends = friends.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'Friends',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? const Center(
                  child: Text(
                    'No friends yet',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListView.builder(
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(profileUserId: friend['id']),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: friend['profileImageUrl'] != null &&
                                      friend['profileImageUrl'].isNotEmpty
                                  ? CachedNetworkImageProvider(friend['profileImageUrl'])
                                  : null,
                              child: friend['profileImageUrl'] == null || friend['profileImageUrl'].isEmpty
                                  ? const Icon(Icons.person, size: 30, color: AppColors.primary)
                                  : null,
                            ),
                            title: Text(
                              friend['username'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            subtitle: Text(
                              friend['fullName'],
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
