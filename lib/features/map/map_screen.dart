import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/database/app_database.dart';
import '../../data/models/stop.dart';
import 'widgets/stop_marker.dart';
import 'widgets/departure_board.dart';
import '../../data/models/stop_group.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Stop> _stops = [];
  List<StopGroup> _searchResults = [];
  bool _loading = true;
  bool _isSearching = false;
  double _currentZoom = _initialZoom;

  static const _initialCenter = LatLng(50.0755, 14.4378);
  static const _initialZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _loadStops();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadStops() async {
    final stops = await AppDatabase.getAllStops();
    setState(() {
      _stops = stops;
      _loading = false;
    });
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await AppDatabase.searchStopsGrouped(query);

    setState(() {
      _searchResults = results;
    });
  }

  void _onGroupTapped(StopGroup group) {
    _searchFocus.unfocus();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });

    final stop = group.stops.first;
    _mapController.move(LatLng(stop.lat, stop.lng), 16);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          DepartureBoard(stopId: stop.stopId, stopName: stop.stopName),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  List<Stop> get _visibleStops {
    if (_currentZoom >= 15) return _stops; // všetky zastávky
    if (_currentZoom >= 11) {
      return _stops.where((s) => s.stopId.contains(RegExp(r'S\d+$'))).toList();
    }
    return []; // nič
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Mapa
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: _initialZoom,
                    minZoom: 10,
                    maxZoom: 18,
                    onPositionChanged: (position, _) {
                      if (position.zoom != _currentZoom) {
                        setState(() => _currentZoom = position.zoom);
                      }
                    },
                    // Klik na mapu zatvorí search
                    onTap: null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.itransit2',
                    ),
                    MarkerLayer(
                      markers: buildStopMarkers(
                        stops: _visibleStops,
                        onTap: (stop) {
                          // Obal Stop do dočasného StopGroup
                          _onGroupTapped(
                            StopGroup(
                              name: stop.stopName,
                              parentStation: stop.stopId,
                              stops: [stop],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Search bar + výsledky
                SafeArea(
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            decoration: InputDecoration(
                              hintText: 'Hľadaj zastávku...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Colors.blue,
                              ),
                              suffixIcon: _isSearching
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      color: Colors.grey,
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Výsledky vyhľadávania
                      // Výsledky vyhľadávania
                      if (_searchResults.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, _) => Divider(
                                color: Colors.grey.shade100,
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (_, i) {
                                final group = _searchResults[i];
                                final isMetro = group.stops.first.stopId
                                    .contains(RegExp(r'S\d+$'));

                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isMetro
                                        ? Icons.subway_rounded
                                        : Icons.directions_bus_rounded,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  title: Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${group.stops.length} ${group.stops.length == 1 ? 'platforma' : 'platformy'}',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () => _onGroupTapped(group),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
