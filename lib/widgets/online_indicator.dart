import 'package:flutter/material.dart';

class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final double size;

  const OnlineIndicator({
    super.key,
    required this.isOnline,
    this.lastSeen,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isOnline ? 'Online' : _getLastSeenText(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  String _getLastSeenText() {
    if (lastSeen == null) return 'Never seen';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inDays > 0) {
      return 'Last seen ${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}