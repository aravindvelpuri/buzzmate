import 'package:buzzmate/screens/settings_screen.dart';
import 'package:buzzmate/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import 'friends_list_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? profileUserId;

  const ProfileScreen({super.key, this.profileUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isCurrentUser = false;
  String? _currentUserId;
  String _friendshipStatus = 'none';

  List<String> _getListData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is List) return List<String>.from(value);
    return [];
  }

  int _getIntData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    return 0;
  }

  String _getStringData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String) return value;
    return '';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('loggedInUser');

      final profileUserId = widget.profileUserId ?? _currentUserId;
      _isCurrentUser = profileUserId == _currentUserId;

      final userDoc = await _firestore
          .collection('users')
          .doc(profileUserId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data()!;
          _isLoading = false;
        });
      }

      if (!_isCurrentUser && _currentUserId != null) {
        _checkFriendshipStatus();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFriendshipStatus() async {
    try {
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (!currentUserDoc.exists) return;

      final currentUserData = currentUserDoc.data()!;
      final currentUserFriends = _getListData(currentUserData, 'friends');
      final currentUserRequests = _getListData(
        currentUserData,
        'friendRequests',
      );
      final currentUserPending = _getListData(
        currentUserData,
        'pendingRequests',
      );

      if (currentUserFriends.contains(widget.profileUserId)) {
        setState(() => _friendshipStatus = 'friends');
      } else if (currentUserRequests.contains(widget.profileUserId)) {
        setState(() => _friendshipStatus = 'requested');
      } else if (currentUserPending.contains(widget.profileUserId)) {
        setState(() => _friendshipStatus = 'pending');
      }
    } catch (e) {}
  }

  Future<void> _sendFriendRequest() async {
    try {
      final batch = _firestore.batch();

      final profileUserRef = _firestore
          .collection('users')
          .doc(widget.profileUserId);
      batch.update(profileUserRef, {
        'friendRequests': FieldValue.arrayUnion([_currentUserId]),
      });

      final currentUserRef = _firestore.collection('users').doc(_currentUserId);
      batch.update(currentUserRef, {
        'pendingRequests': FieldValue.arrayUnion([widget.profileUserId]),
      });

      await batch.commit();

      setState(() => _friendshipStatus = 'pending');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend request sent')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send request')));
      }
    }
  }

  Future<void> _cancelFriendRequest() async {
    try {
      final batch = _firestore.batch();

      final profileUserRef = _firestore
          .collection('users')
          .doc(widget.profileUserId);
      batch.update(profileUserRef, {
        'friendRequests': FieldValue.arrayRemove([_currentUserId]),
      });

      final currentUserRef = _firestore.collection('users').doc(_currentUserId);
      batch.update(currentUserRef, {
        'pendingRequests': FieldValue.arrayRemove([widget.profileUserId]),
      });

      await batch.commit();

      setState(() => _friendshipStatus = 'none');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel request')),
        );
      }
    }
  }

  Future<void> _unfriend() async {
    try {
      final batch = _firestore.batch();

      final profileUserRef = _firestore
          .collection('users')
          .doc(widget.profileUserId);
      batch.update(profileUserRef, {
        'friends': FieldValue.arrayRemove([_currentUserId]),
        'followers': FieldValue.increment(-1),
      });

      final currentUserRef = _firestore.collection('users').doc(_currentUserId);
      batch.update(currentUserRef, {
        'friends': FieldValue.arrayRemove([widget.profileUserId]),
        'following': FieldValue.increment(-1),
      });

      await batch.commit();

      setState(() => _friendshipStatus = 'none');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unfriended')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to unfriend')));
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _editProfile() async {
    if (_userData == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          userId: _currentUserId!,
          currentUserData: _userData!,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadUserData();
    }
  }

  Widget _getActionButton() {
    switch (_friendshipStatus) {
      case 'friends':
        return OutlinedButton.icon(
          onPressed: _unfriend,
          icon: const Icon(Icons.person_remove),
          label: const Text("Unfriend"),
        );
      case 'pending':
        return OutlinedButton.icon(
          onPressed: _cancelFriendRequest,
          icon: const Icon(Icons.cancel),
          label: const Text("Cancel Request"),
        );
      case 'requested':
        return OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.hourglass_empty),
          label: const Text("Requested"),
        );
      default:
        return ElevatedButton.icon(
          onPressed: _sendFriendRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.person_add),
          label: const Text("Add Friend"),
        );
    }
  }

  void _openFriendsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FriendsListScreen(userId: widget.profileUserId ?? _currentUserId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final username = _userData!['username'] ?? 'Unknown';
    final fullName = _userData!['fullName'] ?? '';
    final bio = _getStringData(_userData!, 'bio');
    final profileImageUrl = _userData!['profileImageUrl'];
    final followers = _getIntData(_userData!, 'followers');
    final following = _getIntData(_userData!, 'following');
    final friends = _getListData(_userData!, 'friends').length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
        leading: !_isCurrentUser
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: _isCurrentUser
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black87),
                  onPressed: _editProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black87),
                  onPressed: _logout,
                ),
              ]
            : null,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Picture
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(profileImageUrl)
                        : null,
                    child: profileImageUrl == null || profileImageUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Full Name
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Username
                  Text("@$username", style: TextStyle(color: Colors.grey[600])),

                  const SizedBox(height: 16),

                  // Stats Row with Purple Background
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(friends, "Friends", onTap: _openFriendsList),
                        _buildStat(followers, "Followers"),
                        _buildStat(following, "Following"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Button
            if (!_isCurrentUser) _getActionButton(),

            const SizedBox(height: 20),

            // Bio Section
            if (bio.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    bio,
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (_isCurrentUser) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SettingsContent(), // ✅ shows settings inside profile
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(int count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
