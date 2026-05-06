import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class LocationInfoCard extends StatelessWidget {
  final LatLng position;

  const LocationInfoCard({super.key, required this.position});

  String _formatCoordinate(double value, bool isLat) {
    final direction = isLat ? (value >= 0 ? 'N' : 'S') : (value >= 0 ? 'E' : 'W');
    final abs = value.abs();
    final degrees = abs.floor();
    final minutes = ((abs - degrees) * 60).floor();
    final seconds = (((abs - degrees) * 60 - minutes) * 60).toStringAsFixed(1);
    return '$degrees $minutes $seconds $direction';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00D4FF).withOpacity(0.15)),
          child: const Icon(Icons.location_on_rounded, color: Color(0xFF00D4FF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Tvoja poloha', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(
            '${_formatCoordinate(position.latitude, true)}  ${_formatCoordinate(position.longitude, false)}',
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ])),
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: const Color(0xFF00FF88),
            boxShadow: [BoxShadow(color: const Color(0xFF00FF88).withOpacity(0.6), blurRadius: 6, spreadRadius: 1)],
          ),
        ),
      ]),
    );
  }
}
