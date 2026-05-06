import 'package:flutter/material.dart';

class SoundMarker extends StatefulWidget {
  final bool isPlaying;
  const SoundMarker({super.key, required this.isPlaying});

  @override
  State<SoundMarker> createState() => _SoundMarkerState();
}

class _SoundMarkerState extends State<SoundMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(alignment: Alignment.center, children: [
          if (widget.isPlaying)
            Transform.scale(
              scale: _animation.value,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4444).withOpacity(0.2),
                ),
              ),
            ),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isPlaying
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF1A1A2E),
              border: Border.all(
                color: widget.isPlaying
                    ? const Color(0xFFFF4444)
                    : const Color(0xFF00D4FF),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isPlaying ? const Color(0xFFFF4444) : const Color(0xFF00D4FF)).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              widget.isPlaying ? Icons.stop_rounded : Icons.music_note_rounded,
              color: widget.isPlaying ? Colors.white : const Color(0xFF00D4FF),
              size: 18,
            ),
          ),
        ]);
      },
    );
  }
}
