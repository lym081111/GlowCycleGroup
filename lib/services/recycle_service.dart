import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/recycle_lookup.dart';
import '../models/recycle_point.dart';

/// Fetches recycling drop-off points from the OpenStreetMap Overpass API,
/// centred on the device's location when it is available.
class RecycleService {
  /// Campus reference used when the device location is unavailable.
  static const utarLat = 4.3380;
  static const utarLng = 101.1430;

  /// OpenStreetMap has no recycling amenity mapped within 18 km of the UTAR
  /// Kampar reference, so the original radius could only ever return an empty
  /// set there. The nearest mapped point sits about 30 km out.
  static const searchRadiusMetres = 50000;

  /// Reads the device position, or null when location is off, declined, or
  /// too slow to be worth waiting for.
  ///
  /// Never throws: a refused permission is an ordinary outcome here, and the
  /// caller simply searches around campus instead.
  static Future<Position?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (exception) {
      if (kDebugMode) {
        debugPrint('Location unavailable, using campus reference: $exception');
      }
      return null;
    }
  }

  /// Searches around [latitude]/[longitude], or the campus reference when
  /// they are null.
  static Future<RecycleLookup> fetchRecyclePoints({
    double? latitude,
    double? longitude,
  }) async {
    final usingDevice = latitude != null && longitude != null;
    final lat = latitude ?? utarLat;
    final lng = longitude ?? utarLng;
    final origin = usingDevice
        ? 'your current location'
        : 'the UTAR Kampar reference';
    final radiusKm = (searchRadiusMetres / 1000).round();

    final query =
        '''
[out:json][timeout:25];
(
  node["amenity"="recycling"](around:$searchRadiusMetres,$lat,$lng);
  way["amenity"="recycling"](around:$searchRadiusMetres,$lat,$lng);
  relation["amenity"="recycling"](around:$searchRadiusMetres,$lat,$lng);
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
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        return RecycleLookup.fallback(
          points: fallbackPoints,
          originLabel: origin,
          note:
              'OpenStreetMap replied ${response.statusCode}. Showing demo points.',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];
      final points = elements.map((element) {
        final item = element as Map<String, dynamic>;
        final tags = (item['tags'] as Map?)?.cast<String, dynamic>() ?? {};
        final pointLat = (item['lat'] ?? item['center']?['lat'] ?? lat)
            .toDouble();
        final pointLon = (item['lon'] ?? item['center']?['lon'] ?? lng)
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
              ? 'OpenStreetMap recycling location'
              : address,
          acceptedItems: _acceptedItems(tags),
          openingHours:
              (tags['opening_hours'] ?? 'Check with venue before visiting')
                  .toString(),
          latitude: pointLat,
          longitude: pointLon,
          distanceKm: distanceKm(lat, lng, pointLat, pointLon),
        );
      }).toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (points.isEmpty) {
        // An empty result is not a failure: the service answered, this area
        // simply has nothing mapped. Saying so beats blaming the endpoint.
        return RecycleLookup.fallback(
          points: fallbackPoints,
          originLabel: origin,
          note:
              'OpenStreetMap has no recycling point mapped within $radiusKm km '
              'of $origin. Showing demo points instead.',
        );
      }
      return RecycleLookup(
        points: points.take(8).toList(),
        isLive: true,
        originLabel: origin,
      );
    } catch (exception) {
      if (kDebugMode) {
        debugPrint('Overpass lookup failed: $exception');
      }
      return RecycleLookup.fallback(
        points: fallbackPoints,
        originLabel: origin,
        note: 'Could not reach OpenStreetMap. Showing demo points.',
      );
    }
  }

  /// Turns the OSM recycling tags into a readable list of accepted materials.
  static String _acceptedItems(Map<String, dynamic> tags) {
    final accepted = tags.entries
        .where(
          (entry) => entry.key.startsWith('recycling:') && entry.value == 'yes',
        )
        .map((entry) => entry.key.substring('recycling:'.length))
        .map((item) => item.replaceAll('_', ' '))
        .toList();
    if (accepted.isEmpty) {
      return 'Check on site which materials are accepted';
    }
    return accepted.join(', ');
  }

  /// Curated records that keep the screen demonstrable when the live search
  /// returns nothing.
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
      distanceKm: distanceKm(utarLat, utarLng, 4.3120, 101.1530),
    ),
    RecyclePoint(
      id: 'rp003',
      name: 'Eco Beauty Drop-Off Point',
      address: 'Beauty retail counter, Kampar',
      acceptedItems: 'Empty beauty bottles, compact cases, clean jars',
      openingHours: 'Sat-Sun, 11:00 AM - 7:00 PM',
      latitude: 4.3290,
      longitude: 101.1480,
      distanceKm: distanceKm(utarLat, utarLng, 4.3290, 101.1480),
    ),
  ];

  /// Great-circle distance between two coordinates, in kilometres.
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
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
