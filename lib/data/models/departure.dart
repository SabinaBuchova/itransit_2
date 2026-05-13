class Departure {
  final String routeShortName; // číslo linky napr. "22", "A"
  final String headsign;       // smer napr. "Bílá Hora"
  final DateTime scheduledTime;
  final int? delaySeconds;     // meškanie v sekundách, null = neznáme

  Departure({
    required this.routeShortName,
    required this.headsign,
    required this.scheduledTime,
    this.delaySeconds,
  });

  // Reálny čas odchodu = plánovaný čas + meškanie
  DateTime get realTime => scheduledTime.add(
    Duration(seconds: delaySeconds ?? 0),
  );

  // Koľko minút do odchodu od teraz
  int get minutesUntilDeparture =>
      realTime.difference(DateTime.now()).inMinutes;

  bool get isDelayed => delaySeconds != null && delaySeconds! > 60;
}