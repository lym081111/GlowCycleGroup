import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/recycle_point.dart';

/// Fetches recycling drop-off points from the OpenStreetMap Overpass API.
class RecycleService {
  static const _utarLat = 4.3380;
  static const _utarLng = 101.1430;

  static Future<List<RecyclePoint>> fetchRecyclePoints() async {
    const query = '''
[out:json][timeout:20];
(
  node["amenity"="recycling"](around:18000,4.3380,101.1430);
  way["amenity"="recycling"](around:18000,4.3380,101.1430);
  relation["amenity"="recycling"](around:18000,4.3380,101.1430);
);
out center 12;
''';
    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {'Content-Type': 'text/plain'},
            body: query,
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return fallbackPoints;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];
      final points = elements.take(8).map((element) {
        final item = element as Map<String, dynamic>;
        final tags = (item['tags'] as Map?)?.cast<String, dynamic>() ?? {};
        final lat = (item['lat'] ?? item['center']?['lat'] ?? _utarLat)
            .toDouble();
        final lon = (item['lon'] ?? item['center']?['lon'] ?? _utarLng)
            .toDouble();
        final name = (tags['name'] ?? 'Community Recycling Point').toString();
        final address = [
          tags['addr:street'],
          tags['addr:city'],
          tags['addr:postcode'],
        ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
        return RecyclePoint(
          id: item['id'].toString(),
          name: name,
          address: address.isEmpty
              ? 'OpenStreetMap recycling location near Kampar'
              : address,
          acceptedItems:
              'Plastic bottles, glass jars, paper, cosmetic containers if cleaned',
          openingHours:
              (tags['opening_hours'] ?? 'Check with venue before visiting')
                  .toString(),
          latitude: lat,
          longitude: lon,
          distanceKm: _distanceKm(_utarLat, _utarLng, lat, lon),
        );
      }).toList();
      return points.isEmpty ? fallbackPoints : points;
    } catch (_) {
      return fallbackPoints;
    }
  }

  /// Curated records that keep the screen demonstrable when Overpass is
  /// unreachable.
  static final fallbackPoints = [
    RecyclePoint(
      id: 'rp001',
      name: 'UTAR Eco Collection Corner',
      address: 'UTAR Campus Main Lobby, Kampar',
      acceptedItems: 'Plastic bottles, glass jars, cosmetic containers',
      openingHours: 'Mon-Fri, 9:00 AM - 5:00 PM',
      latitude: 4.3380,
      longitude: 101.1430,
      distanceKm: 0,
    ),
    RecyclePoint(
      id: 'rp002',
      name: 'Kampar Recycling Centre',
      address: 'Kampar Town Area',
      acceptedItems: 'Plastic packaging, paper, glass',
      openingHours: 'Daily, 10:00 AM - 6:00 PM',
      latitude: 4.3120,
      longitude: 101.1530,
      distanceKm: _distanceKm(_utarLat, _utarLng, 4.3120, 101.1530),
    ),
    RecyclePoint(
      id: 'rp003',
      name: 'Eco Beauty Drop-Off Point',
      address: 'Beauty retail counter, Kampar',
      acceptedItems: 'Empty beauty bottles, compact cases, clean jars',
      openingHours: 'Sat-Sun, 11:00 AM - 7:00 PM',
      latitude: 4.3290,
      longitude: 101.1480,
      distanceKm: _distanceKm(_utarLat, _utarLng, 4.3290, 101.1480),
    ),
  ];

  /// Great-circle distance between two coordinates, in kilometres.
  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _degToRad(double deg) => deg * pi / 180;
}
