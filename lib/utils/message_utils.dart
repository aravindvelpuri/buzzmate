import 'package:intl/intl.dart';

class MessageUtils {
  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yy').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Never seen';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 0) {
      return 'Last seen ${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else {
      return 'Online now';
    }
  }

  static String truncateMessage(String message, {int maxLength = 50}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  static List<String> extractMentions(String message) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(message);
    return matches.map((match) => match.group(1)!).toList();
  }
}