import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buzzmate/services/chat_service.dart';
import 'package:buzzmate/theme/colors.dart';
import 'package:intl/intl.dart';

class ScheduledMessagesScreen extends StatefulWidget {
  final String currentUserId;

  const ScheduledMessagesScreen({super.key, required this.currentUserId});

  @override
  State<ScheduledMessagesScreen> createState() => _ScheduledMessagesScreenState();
}

class _ScheduledMessagesScreenState extends State<ScheduledMessagesScreen> {
  final ChatService _chatService = ChatService();
  final Map<String, dynamic> _userCache = {};
  final Map<String, dynamic> _chatCache = {};
  List<Map<String, dynamic>> _scheduledMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledMessages();
  }

  Future<void> _loadScheduledMessages() async {
    try {
      final results = await _chatService.getScheduledMessages(widget.currentUserId);
      await _loadRelatedData(results);
      
      setState(() {
        _scheduledMessages = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading scheduled messages: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedData(List<Map<String, dynamic>> messages) async {
    final userIds = messages.map((m) => m['senderId']).toSet();
    final chatIds = messages.map((m) => m['chatId']).toSet();

    for (final userId in userIds) {
      if (!_userCache.containsKey(userId)) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          _userCache[userId] = userDoc.data();
        }
      }
    }

    for (final chatId in chatIds) {
      if (!_chatCache.containsKey(chatId)) {
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();
        
        if (chatDoc.exists) {
          _chatCache[chatId] = chatDoc.data();
        }
      }
    }
  }

  Future<void> _editScheduledMessage(String messageId, Map<String, dynamic> updates) async {
    try {
      await _chatService.updateScheduledMessage(messageId, updates);
      await _loadScheduledMessages();
    } catch (e) {
      debugPrint("Error editing scheduled message: $e");
    }
  }

  Future<void> _deleteScheduledMessage(String messageId) async {
    try {
      await _chatService.deleteScheduledMessage(messageId);
      setState(() {
        _scheduledMessages.removeWhere((m) => m['id'] == messageId);
      });
    } catch (e) {
      debugPrint("Error deleting scheduled message: $e");
    }
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
        title: const Text('Scheduled Messages'),
      ),
      body: _scheduledMessages.isEmpty
          ? const Center(
              child: Text(
                'No scheduled messages',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              itemCount: _scheduledMessages.length,
              itemBuilder: (context, index) {
                final message = _scheduledMessages[index];
                final chat = _chatCache[message['chatId']];

                return ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(message['content']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To: ${chat?['name'] ?? 'Unknown'}'),
                      Text('Scheduled: ${DateFormat('MMM dd, yyyy - HH:mm').format(message['scheduledTime'])}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditDialog(message);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteScheduledMessage(message['id']);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create scheduled message screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> message) {
    final contentController = TextEditingController(text: message['content']);
    DateTime selectedDate = message['scheduledTime'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Scheduled Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && mounted) {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (time != null && mounted) {
                      setState(() {
                        selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Text(DateFormat('MMM dd, yyyy - HH:mm').format(selectedDate)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _editScheduledMessage(message['id'], {
                  'content': contentController.text,
                  'scheduledTime': selectedDate,
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}