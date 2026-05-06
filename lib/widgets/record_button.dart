import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RecordButton extends StatefulWidget {
  final bool isEnabled;
  final bool isRecording;
  final VoidCallback onRecord;

  const RecordButton({
    super.key,
    required this.isEnabled,
    required this.isRecording,
    required this.onRecord,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) {
    if (!widget.isEnabled) return;
    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails d) {
    if (!widget.isEnabled) return;
    _controller.reverse();
    widget.onRecord();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.isRecording;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.isEnabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isRecording
                        ? [const Color(0xFFFF4444), const Color(0xFFCC0000)]
                        : [const Color(0xFF00D4FF), const Color(0xFF0088CC)],
                  )
                : null,
            color: widget.isEnabled ? null : Colors.white.withOpacity(0.08),
            boxShadow: widget.isEnabled
                ? [
                    BoxShadow(
                      color: isRecording
                          ? const Color(0xFFFF4444).withOpacity(0.5)
                          : const Color(0xFF00D4FF).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            size: 34,
            color: widget.isEnabled ? Colors.white : Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}