import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/record_button.dart';
import '../widgets/location_info_card.dart';
import '../widgets/sound_marker.dart';
import '../models/sound_entry.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  bool _locationError = false;
  String _errorMessage = '';
  bool _isRecording = false;
  String? _playingPath;

  final List<SoundEntry> _sounds = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() { _isLoadingLocation = true; _locationError = false; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _isLoadingLocation = false; _locationError = true; _errorMessage = 'Zapni polohu v nastaveniach.'; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _isLoadingLocation = false; _locationError = true; _errorMessage = 'Pristup k polohe bol zamietnuty.'; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _isLoadingLocation = false; _locationError = true; _errorMessage = 'Povol pristup k polohe v Nastaveniach.'; });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() { _currentPosition = latLng; _isLoadingLocation = false; });
      _mapController.move(latLng, 13.0);
    } catch (e) {
      setState(() { _isLoadingLocation = false; _locationError = true; _errorMessage = 'Nepodarilo sa ziskat polohu.'; });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (path != null && _currentPosition != null) {
        setState(() {
          _isRecording = false;
          _sounds.add(SoundEntry(
            path: path,
            position: _currentPosition!,
            createdAt: DateTime.now(),
          ));
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Zvuk nahratý a pridaný na mapu!'),
              backgroundColor: const Color(0xFF00D4FF).withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } else {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/sound_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
      setState(() { _isRecording = true; });
    }
  }

  Future<void> _playSound(SoundEntry sound) async {
    if (_playingPath == sound.path) {
      await _player.stop();
      setState(() { _playingPath = null; });
      return;
    }
    setState(() { _playingPath = sound.path; });
    await _player.setFilePath(sound.path);
    await _player.play();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() { _playingPath = null; });
      }
    });
  }

  void _showSoundSheet(SoundEntry sound) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF12121A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D4FF).withOpacity(0.15),
                ),
                child: const Icon(Icons.music_note_rounded, color: Color(0xFF00D4FF), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Nahratý zvuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(
                  '${sound.createdAt.day}.${sound.createdAt.month}.${sound.createdAt.year} ${sound.createdAt.hour}:${sound.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                ),
              ])),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _playSound(sound);
                    setModalState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: _playingPath == sound.path
                            ? [const Color(0xFFFF4444), const Color(0xFFCC0000)]
                            : [const Color(0xFF00D4FF), const Color(0xFF0088CC)],
                      ),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        _playingPath == sound.path ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: Colors.white, size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _playingPath == sound.path ? 'Zastavit' : 'Prehrat',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() { _sounds.remove(sound); });
                  Navigator.pop(context);
                },
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.white.withOpacity(0.6), size: 22),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition ?? const LatLng(48.1486, 17.1077),
            initialZoom: 3.0, minZoom: 2.0, maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.soundmagic.app',
            ),
            // Sound markery
            MarkerLayer(
              markers: _sounds.map((sound) => Marker(
                point: sound.position,
                width: 44, height: 44,
                child: GestureDetector(
                  onTap: () => _showSoundSheet(sound),
                  child: SoundMarker(isPlaying: _playingPath == sound.path),
                ),
              )).toList(),
            ),
            // Aktualna poloha
            if (_currentPosition != null)
              MarkerLayer(markers: [
                Marker(
                  point: _currentPosition!, width: 60, height: 60,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Stack(alignment: Alignment.center, children: [
                      Transform.scale(scale: _pulseAnimation.value,
                        child: Container(width: 50, height: 50,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            color: const Color(0xFF00D4FF).withOpacity(0.15),
                            border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.4), width: 1),
                          ),
                        ),
                      ),
                      Container(width: 16, height: 16,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00D4FF),
                          boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.8), blurRadius: 12, spreadRadius: 2)],
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
          ],
        ),
        Positioned(top: 0, left: 0, right: 0, height: 120,
          child: Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [const Color(0xFF0A0A0F).withOpacity(0.9), Colors.transparent],
          ))),
        ),
        SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('SoundMagic', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
              Text('Nahraj zvuky sveta', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
            ]),
            const Spacer(),
            if (_sounds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.music_note_rounded, color: Color(0xFF00D4FF), size: 14),
                  const SizedBox(width: 6),
                  Text('${_sounds.length}', style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            if (_isRecording) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFF4444).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF4444))),
                  const SizedBox(width: 8),
                  const Text('Nahrava sa...', style: TextStyle(fontSize: 12, color: Color(0xFFFF4444))),
                ]),
              ),
            ],
            if (_isLoadingLocation && !_isRecording) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D4FF))),
                  const SizedBox(width: 8),
                  Text('Hladam ta...', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                ]),
              ),
            ],
          ]),
        )),
        Positioned(bottom: 0, left: 0, right: 0, height: 280,
          child: Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [const Color(0xFF0A0A0F), const Color(0xFF0A0A0F).withOpacity(0.7), Colors.transparent],
          ))),
        ),
        Positioned(bottom: 0, left: 0, right: 0,
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_currentPosition != null) LocationInfoCard(position: _currentPosition!),
              if (_locationError) Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.location_off_rounded, color: Color(0xFFFF4444), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_errorMessage, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13))),
                  GestureDetector(onTap: _initLocation, child: const Text('Skusit znova', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 13, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                GestureDetector(
                  onTap: _currentPosition != null ? () => _mapController.move(_currentPosition!, 13.0) : null,
                  child: Container(width: 52, height: 52,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.15))),
                    child: Icon(Icons.my_location_rounded, color: Colors.white.withOpacity(0.8), size: 22),
                  ),
                ),
                RecordButton(
                  isEnabled: _currentPosition != null,
                  isRecording: _isRecording,
                  onRecord: _toggleRecording,
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(width: 52, height: 52,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.15))),
                    child: Icon(Icons.queue_music_rounded, color: Colors.white.withOpacity(0.8), size: 22),
                  ),
                ),
              ]),
            ]),
          )),
        ),
      ]),
    );
  }
}