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

  static const _lineA = {
  'U321S1', // Dejvická
  'U157S1', // Bořislavka
  'U462S1', // Nádraží Veleslavín
  'U507S1', // Petřiny
  'U306S1', // Nemocnice Motol
  'U163S1', // Hradčanská
  'U360S1', // Malostranská
  'U703S1', // Staroměstská
  'U1072S1', // Můstek
  'U400S1', // Muzeum
  'U476S1', // Náměstí Míru
  'U209S1', // Jiřího z Poděbrad
  'U118S1', // Flora
  'U921S1', // Želivského
  'U713S1', // Strašnická
  'U953S1', // Skalka
  'U103S1', // Depo Hostivař (ak existuje)
};

static const _lineB = {
  'U572S1', // Zličín (ak existuje)
  'U469S1', // Stodůlky (ak existuje)
  'U354S1', // Luka (ak existuje)
  'U258S1', // Lužiny
  'U602S1', // Nové Butovice
  'U1154S1', // Hůrka
  'U685S1', // Jinonice
  'U957S1', // Radlická
  'U1040S1', // Anděl
  'U458S1', // Smíchovské nádraží
  'U237S1', // Karlovo náměstí
  'U539S1', // Národní třída
  'U1072S1', // Můstek
  'U480S1', // Náměstí Republiky
  'U689S1', // Florenc
  'U758S1', // Křižíkova
  'U655S1', // Invalidovna
  'U529S1', // Palmovka
  'U474S1', // Vysočanská
  'U510S1', // Českomoravská
  'U75S1',  // Kolbenova
  'U135S1', // Hloubětín
  'U818S1', // Rajská zahrada
  'U897S1', // Černý Most
  'U1007S1', // Luka
  'U1140S1', //Stodulky
  'U1141S1', //Zlicin
};

static const _lineC = {
  'U1000S1', // Letňany
  'U332S1',  // Střížkov
  'U603S1',  // Prosek
  'U78S1',   // Ládví
  'U675S1',  // Kobylisy
  'U115S1',  // Nádraží Holešovice
  'U100S1',  // Vltavská
  'U689S1',  // Florenc
  'U142S1',  // Hlavní nádraží
  'U400S1',  // Muzeum
  'U190S1',  // I. P. Pavlova
  'U527S1',  // Vyšehrad
  'U597S1',  // Pražského povstání
  'U385S1',  // Pankrác
  'U50S1',   // Budějovická
  'U228S1',  // Kačerov
  'U601S1',  // Roztyly
  'U52S1',   // Chodov
  'U106S1',  // Opatov
  'U286S1',  // Háje
  
};

List<Color> get _colors {
  const colorA = Color(0xFF00A650);
  const colorB = Color(0xFFFFD500);
  const colorC = Color(0xFFE2001A);
  // print('METRO STOP: ${stop.stopName} | ID: ${stop.stopId}');

  final id = stop.stopId;
  final inA = _lineA.contains(id);
  final inB = _lineB.contains(id);
  final inC = _lineC.contains(id);

  if (inA && inC) return [colorA, colorC]; // Muzeum
  if (inA && inB) return [colorA, colorB]; // Můstek
  if (inB && inC) return [colorB, colorC]; // Florenc

  if (inA) return [colorA];
  if (inB) return [colorB];
  if (inC) return [colorC];

  return [Colors.grey];
}

  bool get _isDark => _colors.length == 3;

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.5),
        child: CustomPaint(
          painter: _SplitCirclePainter(colors: colors),
          child: Center(
            child: Icon(
              Icons.subway_rounded,
              color: _isDark ? Colors.black : Colors.white,
              size: 20,
            ),
          ),
        ),
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

class _SplitCirclePainter extends CustomPainter {
  final List<Color> colors;

  const _SplitCirclePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (colors.length == 1) {
      canvas.drawRect(rect, Paint()..color = colors.first);
      return;
    }

    // Ľavá polovica
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      Paint()..color = colors[0],
    );

    // Pravá polovica
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      Paint()..color = colors[1],
    );
  }

  @override
  bool shouldRepaint(_SplitCirclePainter old) => old.colors != colors;
}
