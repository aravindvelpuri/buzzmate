import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;
  final String currentUserId;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
    required this.currentUserId,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    final filteredUsers = widget.typingUsers.where((id) => id != widget.currentUserId).toList();
    if (filteredUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: child,
              );
            },
            child: const Icon(Icons.circle, size: 8, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Text(
            '${filteredUsers.length} user${filteredUsers.length > 1 ? 's' : ''} typing...',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}