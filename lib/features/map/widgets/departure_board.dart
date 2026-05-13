import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/api/departure_api.dart';
import '../../../data/models/departure.dart';

class DepartureBoard extends StatefulWidget {
  final String stopId;
  final String stopName;

  const DepartureBoard({
    super.key,
    required this.stopId,
    required this.stopName,
  });

  @override
  State<DepartureBoard> createState() => _DepartureBoardState();
}

class _DepartureBoardState extends State<DepartureBoard> {
  List<Departure> _departures = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final departures = await DepartureApi.fetchDepartures(
        widget.stopId,
        widget.stopName,
      );
      if (mounted) {
        setState(() {
          _departures = departures;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Nepodarilo sa načítať odchody';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.stopName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _LiveIndicator(),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const SizedBox(width: 28),
                Text(
                  widget.stopId,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),

          // Obsah
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(_error!,
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          else if (_departures.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Žiadne odchody v najbližšej hodine',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: _departures.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (_, i) =>
                  _DepartureRow(departure: _departures[i]),
            ),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FadeTransition(
          opacity: _controller,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'LIVE',
          style: TextStyle(
            color: Colors.green,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _DepartureRow extends StatelessWidget {
  final Departure departure;

  const _DepartureRow({required this.departure});

  Color get _routeColor {
    final r = departure.routeShortName.toUpperCase();
    if (r == 'A') return const Color(0xFF00A650);
    if (r == 'B') return const Color(0xFFFFD500);
    if (r == 'C') return const Color(0xFFE2001A);
    final n = int.tryParse(r);
    if (n != null && n <= 26) return const Color(0xFFCC0000);
    if (r.startsWith('N')) return const Color(0xFF1A237E);
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = departure.minutesUntilDeparture;
    final isNow = minutes <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Badge linky
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: _routeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              departure.routeShortName,
              style: TextStyle(
                color: _routeColor == const Color(0xFFFFD500)
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Smer
          Expanded(
            child: Text(
              departure.headsign,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Čas
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isNow ? '«' : '$minutes min',
                style: TextStyle(
                  color: departure.isDelayed ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (departure.isDelayed)
                Text(
                  '+${(departure.delaySeconds! / 60).round()} min',
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}