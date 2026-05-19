class FavouriteStop {
  final String stopId;
  final String stopName;

  FavouriteStop({
    required this.stopId,
    required this.stopName,
  });

  Map<String, dynamic> toMap() => {
    'stopId': stopId,
    'stopName': stopName,
  };

  factory FavouriteStop.fromMap(Map<String, dynamic> map) => FavouriteStop(
    stopId: map['stopId'],
    stopName: map['stopName'],
  );
}