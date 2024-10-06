class Location {
  final String formatted;
  final double lat;
  final double lng;

  Location({
    required this.formatted,
    required this.lat,
    required this.lng,
  });

  @override
  String toString() {
    return 'Location(formatted: $formatted, lat: $lat, lng: $lng)';
  }
}
