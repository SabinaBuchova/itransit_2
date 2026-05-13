import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/departure.dart';

class DepartureApi {
  static final _apiKey = dotenv.env['GOLEMIO_API_KEY'];

  static Future<List<Departure>> fetchDepartures(
    String stopId,
    String stopName,
  ) async {
    // S-type = parent station metra → hľadáme podľa mena
    final isMetroStation = stopId.contains(RegExp(r'S\d+$'));

    final url = isMetroStation
        ? Uri.parse(
            'https://api.golemio.cz/v2/pid/departureboards'
            '?names=${Uri.encodeComponent(stopName)}'
            '&minutesBefore=0'
            '&minutesAfter=60'
            '&limit=10'
            '&mode=departures',
          )
        : Uri.parse(
            'https://api.golemio.cz/v2/pid/departureboards'
            '?ids=$stopId'
            '&minutesBefore=0'
            '&minutesAfter=60'
            '&limit=10'
            '&mode=departures',
          );

    final response = await http.get(url, headers: {'x-access-token': _apiKey!});

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Chyba pri načítaní odchodov: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final departures = data['departures'] as List<dynamic>;

    return departures
        .map((d) => _parseDeparture(d))
        .whereType<Departure>() // vyhodí null hodnoty
        .toList();
  }

  static Departure? _parseDeparture(dynamic d) {
    try {
      final route = d['route']['short_name'] as String;
      final headsign = d['trip']['headsign'] as String;
      final scheduledStr = d['departure_timestamp']['scheduled'] as String;
      final scheduled = DateTime.parse(scheduledStr);
      final delaySeconds = d['delay_seconds'] as int?;

      return Departure(
        routeShortName: route,
        headsign: headsign,
        scheduledTime: scheduled,
        delaySeconds: delaySeconds,
      );
    } catch (e) {
      return null;
    }
  }
}
