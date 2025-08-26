import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:buzzmate/models/message_model.dart';
import 'package:buzzmate/widgets/message_reactions.dart';
import 'package:buzzmate/widgets/swipe_to_reply.dart';
import 'package:buzzmate/widgets/disappearing_message_timer.dart';
import 'dart:io';

class ChatBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String currentUserId;
  final String otherUserName;
  final Function(String) onReact;
  final Function() onReply;
  final Function() onEdit;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.otherUserName,
    required this.onReact,
    required this.onReply,
    required this.onEdit,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  void _showReactionMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReactionMenu(
        currentReaction: _getCurrentUserReaction(),
        onReactionSelected: widget.onReact,
      ),
    );
  }

  String? _getCurrentUserReaction() {
    for (var entry in widget.message.reactions.entries) {
      if (entry.value.contains(widget.currentUserId)) {
        return entry.key;
      }
    }
    return null;
  }

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => MessageContextMenu(
        onReply: () {
          Navigator.pop(context);
          widget.onReply();
        },
        onEdit: () {
          Navigator.pop(context);
          widget.onEdit();
        },
        onDelete: () {
          Navigator.pop(context);
        },
        onForward: () {
          Navigator.pop(context);
        },
        onCopy: () {
          Clipboard.setData(ClipboardData(text: widget.message.content));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied to clipboard')),
          );
        },
        onReact: () {
          Navigator.pop(context);
          _showReactionMenu();
        },
        isOwnMessage: widget.isMe,
        canEdit: widget.message.type == 'text',
        canDelete: true,
      ),
    );
  }

  Widget _buildMessageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.replyToMessage != null)
          _buildReplyPreview(widget.message.replyToMessage!),
        _buildMainContent(),
      ],
    );
  }

  Widget _buildReplyPreview(MessageModel replyMessage) {
    final isReplyFromMe = replyMessage.senderId == widget.currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isReplyFromMe ? Colors.blue : Colors.green,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isReplyFromMe ? 'You' : widget.otherUserName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isReplyFromMe ? Colors.blue : Colors.green,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getReplyPreviewContent(replyMessage),
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getReplyPreviewContent(MessageModel message) {
    switch (message.type) {
      case 'image':
        return '📷 Photo';
      case 'location':
        return '📍 Location';
      case 'file':
        return '📎 File';
      default:
        return message.content;
    }
  }

  Widget _buildMainContent() {
    switch (widget.message.type) {
      case 'image':
        return Image.file(File(widget.message.content));
      case 'location':
        final coords = widget.message.content.split(',');
        return Text('Location: ${coords[0]}, ${coords[1]}');
      case 'file':
        return Text('File: ${widget.message.content.split('/').last}');
      default:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.isMe ? Colors.white : Colors.black,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwipeToReply(
      onSwipe: widget.onReply,
      isOwnMessage: widget.isMe,
      child: GestureDetector(
        onLongPress: _showContextMenu,
        onDoubleTap: _showReactionMenu,
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMessageContent(),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(widget.message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    if (widget.message.edited)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'edited',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (widget.message.read)
                      const Icon(Icons.done_all, size: 12, color: Colors.blue),
                    if (widget.message.expireTime != null)
                      DisappearingMessageTimer(
                        expireTime: widget.message.expireTime!,
                        onExpire: () {},
                      ),
                  ],
                ),
                if (widget.message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: MessageReactions(
                      reactions: widget.message.reactions,
                      onReactionTap: widget.onReact,
                      isOwnMessage: widget.isMe,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReactionMenu extends StatelessWidget {
  final Function(String) onReactionSelected;
  final String? currentReaction;
  final List<String> emojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

  ReactionMenu({super.key, required this.onReactionSelected, this.currentReaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: emojis.map((emoji) {
          final isCurrentReaction = emoji == currentReaction;
          return GestureDetector(
            onTap: () {
              onReactionSelected(emoji);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: isCurrentReaction
                  ? BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MessageContextMenu extends StatelessWidget {
  final Function() onReply;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onForward;
  final Function() onCopy;
  final Function() onReact;
  final bool isOwnMessage;
  final bool canEdit;
  final bool canDelete;

  const MessageContextMenu({
    super.key,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onForward,
    required this.onCopy,
    required this.onReact,
    required this.isOwnMessage,
    this.canEdit = true,
    this.canDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnMessage && canEdit)
              _buildMenuItem(Icons.edit, 'Edit', onEdit),
            _buildMenuItem(Icons.reply, 'Reply', onReply),
            _buildMenuItem(Icons.forward, 'Forward', onForward),
            _buildMenuItem(Icons.content_copy, 'Copy', onCopy),
            _buildMenuItem(Icons.emoji_emotions, 'React', onReact),
            if (isOwnMessage && canDelete)
              _buildMenuItem(Icons.delete, 'Delete', onDelete, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, Function() onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(text, style: TextStyle(color: isDestructive ? Colors.red : null)),
      onTap: onTap,
      minLeadingWidth: 24,
    );
  }
}