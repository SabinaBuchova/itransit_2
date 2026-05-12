import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:itransit_2/data/models/stop.dart';
import 'package:itransit_2/data/database/app_database.dart';

class GolemioApi {
  static final apiKey = dotenv.env['GOLEMIO_API_KEY'];

  static Future<List<Stop>> fetchAllStops() async {
    const int limit = 10000;
    int offset = 0;

    List<Stop> allStops = [];

    while (true) {
      final url = Uri.parse(
        "https://api.golemio.cz/v2/gtfs/stops?limit=$limit&offset=$offset",
      );

      final response = await http.get(
        url,
        headers: {"x-access-token": apiKey!},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to load stops");
      }

      final data = jsonDecode(response.body);
      final stops = data["features"] as List<dynamic>;

      if (stops.isEmpty) break;

      for (final item in stops) {
        final stop = parseStop(item);
        if (stop != null) {
          allStops.add(stop);
        }
      }

      offset += limit;
    }

    return allStops;
  }

  static Stop? parseStop(dynamic item) {
    try {
      final props = item["properties"];
      final coords = item["geometry"]["coordinates"];

      return Stop(
        stopId: (props["stop_id"] ?? "").toString(),
        stopName: (props["stop_name"] ?? "").toString(),
        lat: (coords[1] as num).toDouble(),
        lng: (coords[0] as num).toDouble(),
        parentStation: props["parent_station"]?.toString(),
        platformCode: props["platform_code"]?.toString(),
        wheelchairBoarding: props["wheelchair_boarding"] is int
            ? props["wheelchair_boarding"]
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> importStops() async {
    final stops = await GolemioApi.fetchAllStops();

    print("FETCHED: ${stops.length}");

    await AppDatabase.clearStops();

    print("INSERTING INTO DB...");

    await AppDatabase.insertStops(stops);

    print("DONE ✅");
  }
}
