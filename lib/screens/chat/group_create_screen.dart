import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:buzzmate/services/chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupCreateScreen extends StatefulWidget {
  final String currentUserId;

  const GroupCreateScreen({super.key, required this.currentUserId});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<String> _selectedUsers = [];
  final Map<String, dynamic> _userCache = {};
  File? _groupImage;
  bool _isLoading = false;

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

      if (userDoc.exists) {
        final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
        await _loadUserData(friends);
      }
    } catch (e) {
      debugPrint("Error loading friends: $e");
    }
  }

  Future<void> _loadUserData(List<String> userIds) async {
    for (final userId in userIds) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _userCache[userId] = {
          'username': data['username'] ?? 'Unknown',
          'profileImageUrl': data['profileImageUrl'] ?? '',
        };
      }
    }
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _groupImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_groupImage == null) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref('group_avatars/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_groupImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final avatarUrl = await _uploadImage();
      final participants = [..._selectedUsers, widget.currentUserId];

      final groupId = await _chatService.createGroup(
        name: _nameController.text,
        description: _descriptionController.text,
        participants: participants,
        createdBy: widget.currentUserId,
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        Navigator.pop(context, groupId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create group')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Create Group',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.black87),
            onPressed: _createGroup,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Group Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _groupImage != null
                                ? FileImage(_groupImage!)
                                : null,
                            child: _groupImage == null
                                ? const Icon(Icons.camera_alt,
                                    size: 32, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tap to add group image",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Group Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Group Name *",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Description",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Members
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Select Members",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 8),
                        if (_selectedUsers.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children: _selectedUsers.map((userId) {
                              final user = _userCache[userId];
                              return Chip(
                                label: Text(user?['username'] ?? 'Unknown'),
                                avatar: CircleAvatar(
                                  backgroundImage:
                                      (user['profileImageUrl'] ?? '').isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              user['profileImageUrl'])
                                          : null,
                                  child: (user['profileImageUrl'] ?? '')
                                          .isEmpty
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _selectedUsers.remove(userId);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),
                        ..._userCache.entries.map((entry) {
                          final userId = entry.key;
                          final user = entry.value;
                          final isSelected =
                              _selectedUsers.contains(userId);

                          return CheckboxListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedUsers.add(userId);
                                } else {
                                  _selectedUsers.remove(userId);
                                }
                              });
                            },
                            title: Text(user['username']),
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: CircleAvatar(
                              backgroundImage:
                                  (user['profileImageUrl'] ?? '').isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          user['profileImageUrl'])
                                      : null,
                              child: (user['profileImageUrl'] ?? '').isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
