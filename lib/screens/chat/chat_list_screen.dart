// ignore_for_file: unused_field

import 'dart:async';
import 'package:buzzmate/models/chat_model.dart';
import 'package:buzzmate/models/message_model.dart';
import 'package:buzzmate/services/chat_service.dart';
import 'package:buzzmate/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chat_screen.dart';
import 'package:buzzmate/widgets/online_indicator.dart';
import 'package:buzzmate/utils/message_utils.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatListScreen({super.key, required this.currentUserId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, Map<String, dynamic>> _presenceCache = {};
  StreamSubscription? _chatsSubscription;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<MessageModel> _searchResults = [];
  List<ChatModel> _allChats = [];

  @override
  void initState() {
    super.initState();
    _chatService.initialize();
    _setupChatsListener();
  }

  void _setupChatsListener() {
    _chatsSubscription = _chatService
        .getUserChats(widget.currentUserId)
        .listen(
          (chats) {
            setState(() {
              _allChats = chats;
            });
          },
          onError: (error) {
            debugPrint("Chat stream error: $error");
          },
        );
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId]!;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final userData = {
          'username': data['username'] ?? 'Unknown',
          'fullName': data['fullName'] ?? '',
          'profileImageUrl': data['profileImageUrl'] ?? '',
        };

        _userCache[userId] = userData;
        return userData;
      }
    } catch (e) {
      debugPrint("Error fetching user $userId: $e");
    }

    return {'username': 'Unknown', 'fullName': '', 'profileImageUrl': ''};
  }

  Future<Map<String, dynamic>> _getUserPresence(String userId) async {
    if (_presenceCache.containsKey(userId)) return _presenceCache[userId]!;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final presenceData = {
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': data['lastSeen'] != null
              ? (data['lastSeen'] as Timestamp).toDate()
              : null,
        };

        _presenceCache[userId] = presenceData;
        return presenceData;
      }
    } catch (e) {
      debugPrint("Error fetching presence for user $userId: $e");
    }

    return {'isOnline': false, 'lastSeen': null};
  }

  String _getOtherParticipant(List<String> participants) {
    return participants.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
  }

  Future<void> _searchMessages(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _chatService.globalSearch(
        widget.currentUserId,
        query,
      );
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _chatService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔹 Full-width search bar at top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search messages or users...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _searchMessages,
          ),
        ),

        // 🔹 Body content
        Expanded(
          child: _isSearching ? _buildSearchResults() : _buildChatList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching && _searchResults.isEmpty) {
      return const Center(child: Text('No messages found'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final message = _searchResults[index];

        return FutureBuilder<Map<String, dynamic>>(
          future: _getUserData(message.senderId), // 👈 fetch username
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text('Loading...'),
              );
            }

            final userData = snapshot.data!;
            final username = userData['username'] ?? 'Unknown';
            final profileImageUrl = userData['profileImageUrl'] ?? '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: profileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              title: Text(message.content),
              subtitle: Text('From: $username'), // 👈 show username
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: message.chatId,
                      otherUserId: message.senderId,
                      currentUserId: widget.currentUserId,
                      otherUserName: username, // 👈 pass username instead of ID
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<ChatModel>>(
      stream: _chatService.getUserChats(widget.currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return const Center(
            child: Text(
              'No chats yet',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherUserId = _getOtherParticipant(chat.participants);

            return FutureBuilder<Map<String, dynamic>>(
              future:
                  Future.wait([
                    _getUserData(otherUserId),
                    _getUserPresence(otherUserId),
                  ]).then(
                    (results) => {
                      'userData': results[0],
                      'presence': results[1],
                    },
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Loading...'),
                  );
                }

                final userData =
                    snapshot.data?['userData'] ??
                    {'username': 'Unknown', 'profileImageUrl': ''};
                final presence =
                    snapshot.data?['presence'] ??
                    {'isOnline': false, 'lastSeen': null};

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage:
                            userData['profileImageUrl'] != null &&
                                userData['profileImageUrl'].isNotEmpty
                            ? CachedNetworkImageProvider(
                                userData['profileImageUrl'],
                              )
                            : null,
                        child:
                            userData['profileImageUrl'] == null ||
                                userData['profileImageUrl'].isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 30,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      if (!chat.isGroup)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: OnlineIndicator(
                            isOnline: presence['isOnline'],
                            lastSeen: presence['lastSeen'],
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    chat.isGroup ? chat.name : userData['username'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MessageUtils.formatMessageTime(chat.lastMessageTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            chat.unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chat.id,
                          otherUserId: otherUserId,
                          currentUserId: widget.currentUserId,
                          otherUserName: chat.isGroup
                              ? chat.name
                              : userData['username'],
                          isGroup: chat.isGroup,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
