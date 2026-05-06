import 'package:latlong2/latlong.dart';

class SoundEntry {
  final String path;
  final LatLng position;
  final DateTime createdAt;

  SoundEntry({
    required this.path,
    required this.position,
    required this.createdAt,
  });
}
