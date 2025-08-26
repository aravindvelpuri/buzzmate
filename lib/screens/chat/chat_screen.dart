import 'package:buzzmate/services/chat_service.dart';
import 'package:buzzmate/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'chat_bubble.dart';
import 'package:buzzmate/models/message_model.dart';
import 'package:buzzmate/widgets/typing_indicator.dart';
import 'package:buzzmate/services/presence_service.dart';
import 'package:buzzmate/services/block_service.dart';
import 'package:buzzmate/utils/message_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String currentUserId;
  final String otherUserName;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.currentUserId,
    required this.otherUserName,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();
  final BlockService _blockService = BlockService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  List<String> _typingUsers = [];
  Map<String, dynamic> _otherUserPresence = {};
  bool _isBlocked = false;
  bool _isBlockedBy = false;
  String? _editingMessageId;
  MessageModel? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _setupTypingListener();
    _setupPresenceListener();
    _checkBlockStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.chatId, widget.currentUserId);
  }

  void _setupTypingListener() {
    _chatService.getTypingUsers(widget.chatId).listen((typingUsers) {
      setState(() {
        _typingUsers = typingUsers;
      });
    });
  }

  void _setupPresenceListener() {
    if (!widget.isGroup) {
      _presenceService.getUserPresence(widget.otherUserId).listen((presence) {
        setState(() {
          _otherUserPresence = presence;
        });
      });
    }
  }

  Future<void> _checkBlockStatus() async {
    final isBlocked = await _blockService.isUserBlocked(widget.otherUserId);
    final isBlockedBy = await _blockService.isBlockedByUser(widget.otherUserId);
    
    setState(() {
      _isBlocked = isBlocked;
      _isBlockedBy = isBlockedBy;
    });
  }

  Future<void> _sendMessage() async {
    if (_isBlocked || _isBlockedBy) return;
    
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_editingMessageId != null) {
      await _chatService.editMessage(widget.chatId, _editingMessageId!, message);
      setState(() {
        _editingMessageId = null;
      });
    } else if (_replyingToMessage != null) {
      await _chatService.replyToMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        content: message,
        replyToMessageId: _replyingToMessage!.id,
      );
      setState(() {
        _replyingToMessage = null;
      });
    } else {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        content: message,
      );
    }

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        content: picked.path,
        type: 'image',
      );
    }
  }

  Future<void> _sendLocation() async {
    final location = Location();
    final hasPermission = await location.hasPermission();
    
    if (hasPermission == PermissionStatus.denied) {
      await location.requestPermission();
      return;
    }

    final currentLocation = await location.getLocation();
    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      content: '${currentLocation.latitude},${currentLocation.longitude}',
      type: 'location',
    );
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        content: result.files.single.path!,
        type: 'file',
      );
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleTyping(bool isTyping) {
    _chatService.updateTypingStatus(widget.chatId, widget.currentUserId, isTyping);
  }

  Future<void> _reactToMessage(String messageId, String emoji) async {
    await _chatService.reactToMessage(widget.chatId, messageId, widget.currentUserId, emoji);
  }

  void _replyToMessage(MessageModel message) {
    setState(() {
      _replyingToMessage = message;
      _messageFocusNode.requestFocus();
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  void _startEditingMessage(MessageModel message) {
    setState(() {
      _editingMessageId = message.id;
      _messageController.text = message.content;
      _messageFocusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingMessageId = null;
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlocked) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: const Center(child: Text('You have blocked this user')),
      );
    }

    if (_isBlockedBy) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: const Center(child: Text('You have been blocked by this user')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            if (!widget.isGroup && _otherUserPresence.isNotEmpty)
              Text(
                _otherUserPresence['isOnline'] 
                    ? 'Online' 
                    : MessageUtils.formatLastSeen(_otherUserPresence['lastSeen']),
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              // Navigate to chat info screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;

                    return ChatBubble(
                      message: message,
                      isMe: isMe,
                      currentUserId: widget.currentUserId,
                      otherUserName: widget.otherUserName,
                      onReact: (emoji) => _reactToMessage(message.id, emoji),
                      onReply: () => _replyToMessage(message),
                      onEdit: () => _startEditingMessage(message),
                    );
                  },
                );
              },
            ),
          ),
          TypingIndicator(
            typingUsers: _typingUsers,
            currentUserId: widget.currentUserId,
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_editingMessageId != null)
            _buildActionHeader(
              icon: Icons.edit,
              text: 'Editing message',
              onCancel: _cancelEditing,
            ),
          if (_replyingToMessage != null)
            _buildReplyHeader(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _buildAttachmentMenu(),
                  );
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    _handleTyping(value.isNotEmpty);
                  },
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionHeader({required IconData icon, required String text, required Function() onCancel}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.blue)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyingToMessage!.senderId == widget.currentUserId ? 'yourself' : widget.otherUserName}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                Text(
                  _replyingToMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildAttachmentItem(Icons.image, 'Photo', _sendImage),
            _buildAttachmentItem(Icons.attach_file, 'File', _sendFile),
            _buildAttachmentItem(Icons.location_on, 'Location', _sendLocation),
            _buildAttachmentItem(Icons.schedule, 'Schedule', () {
              // Navigate to schedule message screen
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(IconData icon, String label, Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            child: Icon(icon),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}