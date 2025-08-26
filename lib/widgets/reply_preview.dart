import 'package:flutter/material.dart';
import 'package:buzzmate/models/message_model.dart';

class ReplyPreview extends StatelessWidget {
  final MessageModel message;
  final bool isFromCurrentUser;
  final String otherUserName; // <-- add this
  final Function()? onCancel;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    required this.otherUserName, // <-- add this
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isFromCurrentUser ? Colors.blue : Colors.green,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFromCurrentUser ? 'You' : otherUserName, // ✅ show username
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isFromCurrentUser ? Colors.blue : Colors.green,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPreviewContent(),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }

  String _getPreviewContent() {
    switch (message.type) {
      case 'image':
        return '📷 Photo';
      case 'location':
        return '📍 Location';
      case 'file':
        return '📎 File';
      case 'voice':
        return '🎤 Voice message';
      default:
        return message.content;
    }
  }
}
