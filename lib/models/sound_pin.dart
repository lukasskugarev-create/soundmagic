import 'package:latlong2/latlong.dart';

class SoundPin {
  final String id;
  final LatLng position;
  final String filePath;
  final String locationName;
  final DateTime recordedAt;
  final Duration duration;

  SoundPin({
    required this.id,
    required this.position,
    required this.filePath,
    required this.locationName,
    required this.recordedAt,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': position.latitude,
        'lng': position.longitude,
        'filePath': filePath,
        'locationName': locationName,
        'recordedAt': recordedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
      };

  factory SoundPin.fromJson(Map<String, dynamic> json) => SoundPin(
        id: json['id'],
        position: LatLng(json['lat'], json['lng']),
        filePath: json['filePath'],
        locationName: json['locationName'],
        recordedAt: DateTime.parse(json['recordedAt']),
        duration: Duration(milliseconds: json['durationMs'] ?? 0),
      );
}
