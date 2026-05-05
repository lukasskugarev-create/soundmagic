import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import '../models/sound_pin.dart';

class MiniPlayer extends StatefulWidget {
  final SoundPin pin;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const MiniPlayer({
    super.key,
    required this.pin,
    required this.onClose,
    required this.onDelete,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.setFilePath(widget.pin.filePath);
    _duration = widget.pin.duration;
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          setState(() => _isPlaying = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d. MMM yyyy, HH:mm').format(widget.pin.recordedAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Location + close
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF534AB7), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.pin.locationName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () { _player.stop(); widget.onClose(); },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 16),

          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
              activeTrackColor: const Color(0xFF534AB7),
              inactiveTrackColor: Colors.grey[200],
              thumbColor: const Color(0xFF534AB7),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble()
                  : 0,
              max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1,
              onChanged: (val) => _player.seek(Duration(milliseconds: val.toInt())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                Text(_formatDuration(_duration), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  _player.stop();
                  widget.onDelete();
                },
              ),
              const SizedBox(width: 24),
              // Play/pause
              GestureDetector(
                onTap: () => _isPlaying ? _player.pause() : _player.play(),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF534AB7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Replay
              IconButton(
                icon: const Icon(Icons.replay, color: Colors.grey),
                onPressed: () async {
                  await _player.seek(Duration.zero);
                  _player.play();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
