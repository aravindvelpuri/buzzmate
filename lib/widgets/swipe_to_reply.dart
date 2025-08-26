import 'package:flutter/material.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final Function() onSwipe;
  final bool isOwnMessage;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onSwipe,
    required this.isOwnMessage,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.5, 0),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (widget.isOwnMessage) return;
        
        setState(() {
          _dragDistance += details.delta.dx;
          if (_dragDistance > 100) _dragDistance = 100;
          if (_dragDistance < 0) _dragDistance = 0;
          _controller.value = _dragDistance / 100;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragDistance > 60) {
          widget.onSwipe();
        }
        setState(() {
          _dragDistance = 0;
          _controller.reverse();
        });
      },
      child: Stack(
        children: [
          SlideTransition(
            position: _animation,
            child: widget.child,
          ),
          if (_dragDistance > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Opacity(
                opacity: _dragDistance / 100,
                child: const Icon(Icons.reply, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}