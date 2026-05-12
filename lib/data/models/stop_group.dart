import 'stop.dart';

class StopGroup {
  final String name;
  final String? parentStation;
  final List<Stop> stops;

  StopGroup({
    required this.name,
    required this.stops,
    this.parentStation,
  });
}