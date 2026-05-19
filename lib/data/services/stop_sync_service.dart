import 'package:shared_preferences/shared_preferences.dart';
import '../api/golemio_api.dart';
import '../database/app_database.dart';

class StopSyncService {
  static const _lastSyncKey = 'stops_last_sync';
  static const _syncIntervalDays = 7;

  static Future<void> syncIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);

    final shouldSync = lastSync == null || _isOutdated(lastSync);

    if (!shouldSync) {
      // Skontroluj či je DB prázdna (napr. po reinstalácii)
      final stops = await AppDatabase.getAllStops();
      if (stops.isNotEmpty) {
        print('SYNC: DB je aktuálna, preskakujem');
        return;
      }
    }

    print('SYNC: Sťahujem zastávky...');
    await GolemioApi.importStops();

    // Ulož čas posledného importu
    await prefs.setString(
      _lastSyncKey,
      DateTime.now().toIso8601String(),
    );

    print('SYNC: Hotovo ✅');
  }

  static bool _isOutdated(String lastSyncStr) {
    final lastSync = DateTime.parse(lastSyncStr);
    final diff = DateTime.now().difference(lastSync).inDays;
    return diff >= _syncIntervalDays;
  }
}