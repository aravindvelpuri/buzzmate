import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzmate/services/chat_service.dart';
import 'package:buzzmate/services/block_service.dart';
import 'package:buzzmate/utils/file_utils.dart';
import 'dart:convert';

class ChatSettingsScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final bool isGroup;

  const ChatSettingsScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    this.isGroup = false,
  });

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final ChatService _chatService = ChatService();
  final BlockService _blockService = BlockService();
  final Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = prefs.getString('chat_${widget.chatId}_settings');
    
    if (settings != null) {
      setState(() {
        _settings.addAll(Map<String, dynamic>.from(json.decode(settings)));
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'chat_${widget.chatId}_settings',
      json.encode(_settings),
    );
  }

  Future<void> _clearChat() async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FileUtils.clearLocalChat(widget.chatId);
              if (mounted) Navigator.pop(context);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportChat() async {
    try {
      final messages = await _chatService.getChatMessages(widget.chatId).first;
      await FileUtils.exportChat(
        messages.map((m) => m.toJson()).toList(),
        widget.chatId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export chat')),
      );
    }
  }

  Future<void> _blockUser() async {
    if (widget.isGroup) return;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _blockService.blockUser(widget.chatId);
              if (mounted) Navigator.pop(context);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Settings'),
      ),
      body: ListView(
        children: [
          // Notification Settings
          const ListTile(
            title: Text('Notifications'),
            subtitle: Text('Manage chat notifications'),
          ),
          SwitchListTile(
            title: const Text('Mute Notifications'),
            value: _settings['muted'] ?? false,
            onChanged: (value) {
              setState(() {
                _settings['muted'] = value;
                _saveSettings();
              });
            },
          ),

          // Privacy Settings
          const Divider(),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text('Chat privacy settings'),
          ),
          SwitchListTile(
            title: const Text('Disappearing Messages'),
            value: _settings['disappearing'] ?? false,
            onChanged: (value) {
              setState(() {
                _settings['disappearing'] = value;
                _saveSettings();
              });
            },
          ),
          if (_settings['disappearing'] ?? false)
            ListTile(
              title: const Text('Message Timer'),
              subtitle: Text(_settings['disappearTime'] ?? '24 hours'),
              onTap: () {
                _showTimerPicker();
              },
            ),

          // Chat Actions
          const Divider(),
          const ListTile(
            title: Text('Actions'),
            subtitle: Text('Chat management actions'),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Chat'),
            onTap: _clearChat,
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('Export Chat'),
            onTap: _exportChat,
          ),

          // Block User (only for individual chats)
          if (!widget.isGroup) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              textColor: Colors.red,
              onTap: _blockUser,
            ),
          ],

          // Group Settings (only for groups)
          if (widget.isGroup) ...[
            const Divider(),
            const ListTile(
              title: Text('Group Settings'),
              subtitle: Text('Manage group settings'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Members'),
              onTap: () {
                // Navigate to group management screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Leave Group'),
              textColor: Colors.red,
              onTap: () {
                // Handle leave group
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showTimerPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Disappear Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimerOption('24 hours', const Duration(hours: 24)),
            _buildTimerOption('7 days', const Duration(days: 7)),
            _buildTimerOption('30 days', const Duration(days: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerOption(String label, Duration duration) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() {
          _settings['disappearTime'] = label;
          _settings['disappearDuration'] = duration.inSeconds;
          _saveSettings();
        });
        Navigator.pop(context);
      },
    );
  }
}