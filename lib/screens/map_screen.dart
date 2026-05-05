import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../models/sound_pin.dart';
import '../models/pin_storage.dart';
import '../widgets/mini_player.dart';
import '../widgets/record_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final AudioRecorder _recorder = AudioRecorder();
  final _uuid = const Uuid();

  List<SoundPin> _pins = [];
  SoundPin? _selectedPin;
  bool _isRecording = false;
  LatLng? _currentPosition;
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPins();
    _initLocation();
  }

  Future<void> _loadPins() async {
    final pins = await PinStorage.loadPins();
    setState(() => _pins = pins);
  }

  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
      _locationLoaded = true;
    });
    _mapController.move(_currentPosition!, 14);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showSnack('Mikrofón nie je povolený');
      return;
    }
    if (_currentPosition == null) {
      _showSnack('Čakám na GPS...');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final id = _uuid.v4();
    final path = '${dir.path}/$id.m4a';

    await _recorder.start(
      RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path == null || _currentPosition == null) return;

    // Get duration
    Duration duration = Duration.zero;
    try {
      final file = File(path);
      if (await file.exists()) {
        // Approximate from file size
        final bytes = await file.length();
        final seconds = (bytes / 16000).round();
        duration = Duration(seconds: seconds);
      }
    } catch (_) {}

    // Reverse geocode via Nominatim
    final locationName = await _getLocationName(_currentPosition!);

    final pin = SoundPin(
      id: _uuid.v4(),
      position: _currentPosition!,
      filePath: path,
      locationName: locationName,
      recordedAt: DateTime.now(),
      duration: duration,
    );

    await PinStorage.addPin(pin);
    setState(() => _pins.add(pin));
    _showSnack('Zvuk uložený! 🎙');
  }

  Future<String> _getLocationName(LatLng pos) async {
    try {
      final placemarks = await Geolocator.getCurrentPosition();
      // Use coordinates as fallback
      return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    } catch (_) {
      return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _deletePin(SoundPin pin) async {
    await PinStorage.deletePin(pin.id);
    setState(() {
      _pins.removeWhere((p) => p.id == pin.id);
      _selectedPin = null;
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(48.1486, 17.1077), // Bratislava default
              initialZoom: 12,
              onTap: (_, __) => setState(() => _selectedPin = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.soundmagic.app',
              ),
              // Sound pins
              MarkerLayer(
                markers: [
                  // Current location
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF534AB7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(color: const Color(0xFF534AB7).withOpacity(0.4), blurRadius: 8)],
                        ),
                      ),
                    ),
                  // Sound pins
                  ..._pins.map((pin) => Marker(
                    point: pin.position,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPin = pin),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _selectedPin?.id == pin.id
                              ? const Color(0xFF534AB7)
                              : const Color(0xFF5DCAA5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.graphic_eq, color: Color(0xFF534AB7), size: 18),
                        const SizedBox(width: 6),
                        const Text('SoundMagic', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Text(
                      '${_pins.length} pinov',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF534AB7)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Record button
          if (_selectedPin == null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (_isRecording)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('● Nahrávam...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  Center(
                    child: RecordButton(
                      isRecording: _isRecording,
                      onTap: _toggleRecording,
                    ),
                  ),
                ],
              ),
            ),

          // Locate me button
          Positioned(
            bottom: _selectedPin != null ? 240 : 130,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'locate',
              backgroundColor: Colors.white,
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(_currentPosition!, 15);
                }
              },
              child: const Icon(Icons.my_location, color: Color(0xFF534AB7)),
            ),
          ),

          // Mini player
          if (_selectedPin != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MiniPlayer(
                key: ValueKey(_selectedPin!.id),
                pin: _selectedPin!,
                onClose: () => setState(() => _selectedPin = null),
                onDelete: () => _deletePin(_selectedPin!),
              ),
            ),
        ],
      ),
    );
  }
}
