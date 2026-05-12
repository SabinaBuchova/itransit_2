import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/stop.dart';
import '../models/stop_group.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDB();
    print("DATABASE INITIALIZED");
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'itransit.db');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  static Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stops (
        stop_id TEXT PRIMARY KEY,
        stop_name TEXT,
        lat REAL,
        lng REAL,
        parent_station TEXT,
        platform_code TEXT,
        wheelchair_boarding INTEGER
      )
    ''');
  }

  static Future<void> insertStops(List<Stop> stops) async {
    final db = await database;

    final batch = db.batch();

    for (final stop in stops.where(_isPragueMhdStop)) {
      batch.insert(
        'stops',
        stop.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<void> clearStops() async {
    final db = await database;

    await db.delete('stops');

    print("STOPS TABLE CLEARED");
  }

  static Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'itransit.db');

    await deleteDatabase(path);

    _db = null;

    print("DATABASE DELETED");
  }

  static Future<List<Stop>> searchStops(String query) async {
    final db = await database;
    final dbQuery = query.toLowerCase().trim();
    final q = _normalizeStopName(query);

    if (q.isEmpty) return [];

    final result = await db.rawQuery(
      '''
      SELECT *
      FROM stops
      WHERE LOWER(stop_name) LIKE ?
        AND lat BETWEEN 49.93 AND 50.18
        AND lng BETWEEN 14.22 AND 14.72
      ORDER BY
        CASE
          WHEN LOWER(stop_name) = ? THEN 0
          WHEN LOWER(stop_name) LIKE ? THEN 1
          ELSE 2
        END,
        stop_name
      LIMIT 200
      ''',
      ['%$dbQuery%', dbQuery, '$dbQuery%'],
    );

    return _dedupeStopsByName(
      result.map((e) => Stop.fromMap(e)).where(_isPragueMhdStop),
    ).take(20).toList();
  }

  static Future<List<StopGroup>> searchStopsGrouped(String query) async {
    final db = await database;
    final dbQuery = query.toLowerCase().trim();
    final q = _normalizeStopName(query);

    if (q.isEmpty) return [];

    final result = await db.rawQuery(
      '''
      SELECT *
      FROM stops
      WHERE LOWER(stop_name) LIKE ?
        AND lat BETWEEN 49.93 AND 50.18
        AND lng BETWEEN 14.22 AND 14.72
      ORDER BY
        CASE
          WHEN LOWER(stop_name) = ? THEN 0
          WHEN LOWER(stop_name) LIKE ? THEN 1
          ELSE 2
        END,
        stop_name
      LIMIT 200
      ''',
      ['%$dbQuery%', dbQuery, '$dbQuery%'],
    );

    final stops = result.map((e) => Stop.fromMap(e)).where(_isPragueMhdStop);
    final groups = groupStops(stops);

    return rankGroups(groups, q).take(20).toList();
  }

  static List<StopGroup> groupStops(Iterable<Stop> stops) {
    final groups = <String, List<Stop>>{};

    for (final stop in stops) {
      final key = _normalizeStopName(stop.stopName);
      groups.putIfAbsent(key, () => []).add(stop);
    }

    return groups.entries.map((entry) {
      entry.value.sort(_compareStopsForSuggestion);

      return StopGroup(
        name: entry.value.first.stopName,
        parentStation: entry.key,
        stops: entry.value,
      );
    }).toList();
  }

  static List<StopGroup> rankGroups(List<StopGroup> groups, String query) {
    final q = _normalizeStopName(query);

    int score(StopGroup group) {
      final name = _normalizeStopName(group.name);
      var value = 1000;

      if (name == q) value -= 500;
      if (name.startsWith(q)) value -= 300;
      if (name.contains(q)) value -= 100;
      if (name.length < 3) value += 200;

      return value;
    }

    groups.sort((a, b) {
      final scoreCompare = score(a).compareTo(score(b));
      if (scoreCompare != 0) return scoreCompare;

      return a.name.compareTo(b.name);
    });

    return groups;
  }

  static List<Stop> _dedupeStopsByName(Iterable<Stop> stops) {
    final deduped = <String, Stop>{};

    for (final stop in stops) {
      final key = _normalizeStopName(stop.stopName);
      final current = deduped[key];

      if (current == null || _compareStopsForSuggestion(stop, current) < 0) {
        deduped[key] = stop;
      }
    }

    return deduped.values.toList();
  }

  static int _compareStopsForSuggestion(Stop a, Stop b) {
    final aHasPlatform = _hasUsefulPlatform(a);
    final bHasPlatform = _hasUsefulPlatform(b);

    if (aHasPlatform != bHasPlatform) {
      return aHasPlatform ? -1 : 1;
    }

    return a.stopName.compareTo(b.stopName);
  }

  static bool _hasUsefulPlatform(Stop stop) {
    final platform = stop.platformCode?.trim();
    return platform != null && platform.isNotEmpty;
  }

  static bool _isPragueMhdStop(Stop stop) {
    final name = _normalizeStopName(stop.stopName);

    if (name.isEmpty) return false;

    final isInsidePrague =
        stop.lat >= 49.93 &&
        stop.lat <= 50.18 &&
        stop.lng >= 14.22 &&
        stop.lng <= 14.72;

    if (!isInsidePrague) return false;

    final railwayOnlyPatterns = [
      ' km',
      'hr.',
      'odb',
      'odbo',
      'vyh',
      'v km',
      'nav',
      'navest',
      'vlecka',
      'naklad',
      'depo kolej',
    ];

    if (name.startsWith('praha-') || name.startsWith('praha ')) {
      return false;
    }

    return !railwayOnlyPatterns.any(name.contains);
  }

  static String _normalizeStopName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u00e1', 'a')
        .replaceAll('\u010d', 'c')
        .replaceAll('\u010f', 'd')
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u011b', 'e')
        .replaceAll('\u00ed', 'i')
        .replaceAll('\u0148', 'n')
        .replaceAll('\u00f3', 'o')
        .replaceAll('\u0159', 'r')
        .replaceAll('\u0161', 's')
        .replaceAll('\u0165', 't')
        .replaceAll('\u00fa', 'u')
        .replaceAll('\u016f', 'u')
        .replaceAll('\u00fd', 'y')
        .replaceAll('\u017e', 'z');
  }
}
