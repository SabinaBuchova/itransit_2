import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/stop.dart';

List<Marker> buildStopMarkers({
  required List<Stop> stops,
  required void Function(Stop stop) onTap,
}) {
  return stops.map((stop) {
    final isMetro = stop.stopId.contains(RegExp(r'S\d+$'));

    return Marker(
      point: LatLng(stop.lat, stop.lng),
      width: isMetro ? 38 : 20,
      height: isMetro ? 38 : 20,
      child: GestureDetector(
        onTap: () => onTap(stop),
        child: isMetro ? _MetroMarker(stop: stop) : _StopMarker(),
      ),
    );
  }).toList();
}

class _MetroMarker extends StatelessWidget {
  final Stop stop;
  const _MetroMarker({required this.stop});

  Color get _color {
    final name = stop.stopName.toLowerCase();
    if (name.contains('(a)')) return const Color(0xFF00A650);
    if (name.contains('(b)')) return const Color(0xFFFFD500);
    if (name.contains('(c)')) return const Color(0xFFE2001A);
    return const Color(0xFF9E9E9E);
  }

  bool get _isDark => _color == const Color(0xFFFFD500);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.subway_rounded,
        color: _isDark ? Colors.black : Colors.white,
        size: 20,
      ),
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1565C0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_bus_rounded,
        color: Color(0xFF1565C0),
        size: 11,
      ),
    );
  }
}