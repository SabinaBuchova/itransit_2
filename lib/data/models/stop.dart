class Stop {
  final String stopId;
  final String stopName;
  final double lat;
  final double lng;
  final String? parentStation;
  final String? platformCode;
  final int? wheelchairBoarding;

  Stop({
    required this.stopId,
    required this.stopName,
    required this.lat,
    required this.lng,
    this.parentStation,
    this.platformCode,
    this.wheelchairBoarding,
  });

  Map<String, dynamic> toMap() {
    return {
      'stop_id': stopId,
      'stop_name': stopName,
      'lat': lat,
      'lng': lng,
      'parent_station': parentStation,
      'platform_code': platformCode,
      'wheelchair_boarding': wheelchairBoarding,
    };
  }

  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      stopId: map['stop_id'],
      stopName: map['stop_name'],
      lat: map['lat'],
      lng: map['lng'],
      parentStation: map['parent_station'],
      platformCode: map['platform_code'],
      wheelchairBoarding: map['wheelchair_boarding'],
    );
  }
}