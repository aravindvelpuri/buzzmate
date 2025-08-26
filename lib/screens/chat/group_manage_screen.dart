import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupManageScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  const GroupManageScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  State<GroupManageScreen> createState() => _GroupManageScreenState();
}

class _GroupManageScreenState extends State<GroupManageScreen> {
  final Map<String, dynamic> _userCache = {};
  late Map<String, dynamic> _groupData;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        _groupData = groupDoc.data()!;
        _isAdmin = List<String>.from(_groupData['admins'] ?? []).contains(widget.currentUserId);
        
        await _loadUserData(List<String>.from(_groupData['participants'] ?? []));
      }
    } catch (e) {
      debugPrint("Error loading group data: $e");
    } finally {
      setState(() => _isLoading = false);
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
  }

  Future<void> _updateGroupInfo(Map<String, dynamic> updates) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.groupId)
          .update(updates);
      
      setState(() {
        _groupData = {..._groupData, ...updates};
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update group')),
      );
    }
  }

  Future<void> _removeMember(String userId) async {
    if (!_isAdmin) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.groupId)
          .update({
            'participants': FieldValue.arrayRemove([userId]),
          });

      setState(() {
        _groupData['participants'] = List<String>.from(_groupData['participants'])
            .where((id) => id != userId)
            .toList();
      });
    } catch (e) {
      debugPrint("Error removing member: $e");
    }
  }

  Future<void> _addAdmin(String userId) async {
    if (!_isAdmin) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.groupId)
          .update({
            'admins': FieldValue.arrayUnion([userId]),
          });

      setState(() {
        _groupData['admins'] = List<String>.from(_groupData['admins'])..add(userId);
      });
    } catch (e) {
      debugPrint("Error adding admin: $e");
    }
  }

  Future<void> _removeAdmin(String userId) async {
    if (!_isAdmin || userId == _groupData['createdBy']) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.groupId)
          .update({
            'admins': FieldValue.arrayRemove([userId]),
          });

      setState(() {
        _groupData['admins'] = List<String>.from(_groupData['admins'])
            .where((id) => id != userId)
            .toList();
      });
    } catch (e) {
      debugPrint("Error removing admin: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final participants = List<String>.from(_groupData['participants'] ?? []);
    final admins = List<String>.from(_groupData['admins'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Info
            _buildGroupInfo(),
            const SizedBox(height: 24),

            // Members List
            const Text('Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...participants.map((userId) {
              final user = _userCache[userId];
              final isAdmin = admins.contains(userId);
              final isCreator = userId == _groupData['createdBy'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user?['profileImageUrl'] != null &&
                          user?['profileImageUrl'].isNotEmpty
                      ? CachedNetworkImageProvider(user!['profileImageUrl'])
                      : null,
                  child: user?['profileImageUrl'] == null ||
                          user?['profileImageUrl'].isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(user?['username'] ?? 'Unknown'),
                subtitle: isCreator
                    ? const Text('Group Creator')
                    : isAdmin
                        ? const Text('Admin')
                        : null,
                trailing: _isAdmin && !isCreator
                    ? PopupMenuButton(
                        itemBuilder: (context) => [
                          if (!isAdmin)
                            const PopupMenuItem(
                              value: 'make_admin',
                              child: Text('Make Admin'),
                            ),
                          if (isAdmin)
                            const PopupMenuItem(
                              value: 'remove_admin',
                              child: Text('Remove Admin'),
                            ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove from Group'),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'make_admin':
                              _addAdmin(userId);
                              break;
                            case 'remove_admin':
                              _removeAdmin(userId);
                              break;
                            case 'remove':
                              _removeMember(userId);
                              break;
                          }
                        },
                      )
                    : null,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Group Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        ListTile(
          title: const Text('Group Name'),
          subtitle: Text(_groupData['name'] ?? 'No name'),
          trailing: _isAdmin
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog('name', 'Group Name', _groupData['name'] ?? '');
                  },
                )
              : null,
        ),
        ListTile(
          title: const Text('Description'),
          subtitle: Text(_groupData['description'] ?? 'No description'),
          trailing: _isAdmin
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog('description', 'Description', _groupData['description'] ?? '');
                  },
                )
              : null,
        ),
        ListTile(
          title: const Text('Created By'),
          subtitle: Text(_userCache[_groupData['createdBy']]?['username'] ?? 'Unknown'),
        ),
      ],
    );
  }

  void _showEditDialog(String field, String title, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter $title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateGroupInfo({field: controller.text});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}