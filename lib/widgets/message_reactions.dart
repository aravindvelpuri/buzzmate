import 'package:flutter/material.dart';

class MessageReactions extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final Function(String) onReactionTap;
  final bool isOwnMessage;
  final String currentUserId;

  const MessageReactions({
    super.key,
    required this.reactions,
    required this.onReactionTap,
    required this.isOwnMessage,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final reactionEntries = reactions.entries.toList();
    
    // Check if current user has reacted
    String? currentUserReaction;
    for (var entry in reactions.entries) {
      if (entry.value.contains(currentUserId)) {
        currentUserReaction = entry.key;
        break;
      }
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactionEntries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        final hasCurrentUser = users.contains(currentUserId);
        
        return GestureDetector(
          onTap: () => onReactionTap(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasCurrentUser 
                  ? (isOwnMessage ? Colors.blue[100] : Colors.grey[200])
                  : Colors.transparent,
              border: Border.all(
                color: hasCurrentUser 
                    ? (isOwnMessage ? Colors.blue : Colors.grey)
                    : Colors.transparent,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  users.length.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: hasCurrentUser 
                        ? (isOwnMessage ? Colors.blue[800] : Colors.grey[800])
                        : Colors.grey[600],
                    fontWeight: hasCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}