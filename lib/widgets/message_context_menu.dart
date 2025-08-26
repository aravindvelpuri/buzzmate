import 'package:flutter/material.dart';

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