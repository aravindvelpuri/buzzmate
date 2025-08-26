import 'dart:async';

import 'package:flutter/material.dart';

class DisappearingMessageTimer extends StatefulWidget {
  final DateTime expireTime;
  final Function() onExpire;

  const DisappearingMessageTimer({
    super.key,
    required this.expireTime,
    required this.onExpire,
  });

  @override
  State<DisappearingMessageTimer> createState() => _DisappearingMessageTimerState();
}

class _DisappearingMessageTimerState extends State<DisappearingMessageTimer> {
  late Duration _remainingTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.expireTime.difference(DateTime.now());
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = widget.expireTime.difference(DateTime.now());
        if (_remainingTime.inSeconds <= 0) {
          timer.cancel();
          widget.onExpire();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remainingTime),
      style: const TextStyle(
        fontSize: 10,
        color: Colors.grey,
      ),
    );
  }
}