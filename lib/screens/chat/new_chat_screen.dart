import 'package:buzzmate/services/chat_service.dart';
import 'package:buzzmate/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  final String currentUserId;

  const NewChatScreen({super.key, required this.currentUserId});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();

      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      final List<String> friendIds =
          List<String>.from(userData['friends'] ?? []);

      if (friendIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final friends = await Future.wait(
        friendIds.map((id) async {
          final friendDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .get();

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

  Future<void> _startChat(String friendId) async {
    try {
      final existingChatId = await _chatService.getExistingChat([
        widget.currentUserId,
        friendId,
      ]);

      String chatId = existingChatId ??
          await _chatService.createChat([
            widget.currentUserId,
            friendId,
          ]);

      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();

      final friendData = friendDoc.data()!;
      final friendName = friendData['username'] ?? 'Unknown';

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserId: friendId,
              currentUserId: widget.currentUserId,
              otherUserName: friendName,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start chat')),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: AppColors.primary,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      title: const Text(
        'Start New Chat',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    final String profileUrl = friend['profileImageUrl'] ?? '';
    final bool hasImage = profileUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => _startChat(friend['id']),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  hasImage ? CachedNetworkImageProvider(profileUrl) : null,
              child: !hasImage
                  ? const Icon(Icons.person,
                      color: AppColors.primary, size: 28)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend['fullName'].isNotEmpty
                        ? friend['fullName']
                        : friend['username'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (friend['fullName'].isNotEmpty)
                    Text(
                      '@${friend['username']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_outlined,
                  color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined,
                          size: 60, color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'No friends found',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start by adding friends to begin chatting.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: ListView.separated(
                    itemCount: _friends.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildFriendTile(_friends[index]),
                  ),
                ),
    );
  }
}
