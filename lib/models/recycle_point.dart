/// A recycling drop-off location, from OpenStreetMap or the curated fallbacks.
class RecyclePoint {
  RecyclePoint({
    required this.id,
    required this.name,
    required this.address,
    required this.acceptedItems,
    required this.openingHours,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String address;
  final String acceptedItems;
  final String openingHours;
  final double latitude;
  final double longitude;
  final double distanceKm;
}
