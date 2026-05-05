import 'package:flutter/material.dart';

class RecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const RecordButton({super.key, required this.isRecording, required this.onTap});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _scaleAnim = Tween(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: widget.isRecording
          ? AnimatedBuilder(
              animation: _scaleAnim,
              builder: (_, __) => Transform.scale(
                scale: _scaleAnim.value,
                child: _buildButton(),
              ),
            )
          : _buildButton(),
    );
  }

  Widget _buildButton() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isRecording ? Colors.redAccent : const Color(0xFF534AB7),
        boxShadow: [
          BoxShadow(
            color: (widget.isRecording ? Colors.redAccent : const Color(0xFF534AB7)).withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        widget.isRecording ? Icons.stop : Icons.mic,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}
