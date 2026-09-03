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

  /// Radii tried in order, nearest first.
  ///
  /// OpenStreetMap coverage is thin outside the larger Malaysian cities, so a
  /// single small radius returns nothing at all around Kampar. Widening in
  /// steps means a user with nothing nearby still sees the closest points that
  /// exist, instead of an empty screen.
  static const searchRadiiMetres = [25000, 100000, 400000];

  /// Overpass rejects the Dart HTTP client's default user agent with 406, and
  /// its usage policy asks callers to identify themselves.
  static const _userAgent = 'GlowCycle/1.0 (UTAR UCCD3223 student project)';

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

      // Low accuracy is deliberate: the search covers 25km, so a fix good to
      // a city block is ample, and it resolves from the network in seconds
      // where a GPS fix can take far longer indoors.
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (exception) {
        // A slow fix used to drop the search back to campus, tens of
        // kilometres away, which silently changed the results. The last known
        // position is far closer to the truth than that.
        if (kDebugMode) {
          debugPrint('Fresh fix failed ($exception), trying last known.');
        }
        return await Geolocator.getLastKnownPosition();
      }
    } catch (exception) {
      if (kDebugMode) {
        debugPrint('Location unavailable, using campus reference: $exception');
      }
      return null;
    }
  }

  /// Last successful lookup, reused briefly so reopening the screen does not
  /// fire another round of queries.
  ///
  /// Overpass rate limits per IP, and a widening search costs up to three
  /// requests, so repeated visits were earning 429s.
  static RecycleLookup? _cached;
  static DateTime? _cachedAt;
  static const _cacheLifetime = Duration(minutes: 5);

  /// Searches around [latitude]/[longitude], or the campus reference when
  /// they are null.
  static Future<RecycleLookup> fetchRecyclePoints({
    double? latitude,
    double? longitude,
    bool forceRefresh = false,
  }) async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheLifetime) {
      return cached;
    }
    final usingDevice = latitude != null && longitude != null;
    final lat = latitude ?? utarLat;
    final lng = longitude ?? utarLng;
    final origin = usingDevice
        ? 'your current location'
        : 'the UTAR Kampar reference';
    final nearRadiusKm = (searchRadiiMetres.first / 1000).round();

    for (final radius in searchRadiiMetres) {
      final radiusKm = (radius / 1000).round();
      try {
        var response = await _post(radius, lat, lng);
        if (response.statusCode == 429 || response.statusCode == 504) {
          // Overpass sheds load rather than queueing. One patient retry
          // clears most of these.
          await Future<void>.delayed(const Duration(seconds: 4));
          response = await _post(radius, lat, lng);
        }
        if (response.statusCode != 200) {
          if (radius != searchRadiiMetres.last) {
            // This radius failed to answer in time. A wider query sometimes
            // succeeds where a narrower one just timed out on Overpass's
            // side, so keep widening before reporting an error.
            continue;
          }
          return RecycleLookup(
            points: const [],
            originLabel: origin,
            originLatitude: lat,
            originLongitude: lng,
            radiusKm: radiusKm,
            nearRadiusKm: nearRadiusKm,
            errorNote: _describeStatus(response.statusCode),
          );
        }
        final points = _parsePoints(response.body, lat, lng);
        if (points.isEmpty && radius != searchRadiiMetres.last) {
          // Nothing this close; reach further before giving up.
          continue;
        }
        final lookup = RecycleLookup(
          points: points.take(8).toList(),
          originLabel: origin,
          originLatitude: lat,
          originLongitude: lng,
          radiusKm: radiusKm,
          nearRadiusKm: nearRadiusKm,
        );
        _cached = lookup;
        _cachedAt = DateTime.now();
        return lookup;
      } catch (exception) {
        if (kDebugMode) {
          debugPrint('Overpass lookup failed at ${radiusKm}km: $exception');
        }
        return RecycleLookup(
          points: const [],
          originLabel: origin,
          originLatitude: lat,
          originLongitude: lng,
          radiusKm: radiusKm,
          nearRadiusKm: nearRadiusKm,
          errorNote: 'Could not reach OpenStreetMap.',
        );
      }
    }

    return RecycleLookup(
      points: const [],
      originLabel: origin,
      originLatitude: lat,
      originLongitude: lng,
      radiusKm: (searchRadiiMetres.last / 1000).round(),
      nearRadiusKm: nearRadiusKm,
    );
  }

  static Future<http.Response> _post(int radius, double lat, double lng) {
    return http
        .post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': _userAgent,
          },
          body: {'data': _query(radius, lat, lng)},
        )
        .timeout(const Duration(seconds: 30));
  }

  /// Says what a non-200 actually means, since the raw number tells the user
  /// nothing about whether waiting will help.
  static String _describeStatus(int code) {
    if (code == 429) {
      return 'OpenStreetMap is limiting requests right now. '
          'Wait a moment and search again.';
    }
    if (code == 504) {
      return 'OpenStreetMap took too long to answer. Try again shortly.';
    }
    return 'OpenStreetMap replied $code.';
  }

  static String _query(int radius, double lat, double lng) {
    return '''
[out:json][timeout:30];
(
  node["amenity"="recycling"](around:$radius,$lat,$lng);
  way["amenity"="recycling"](around:$radius,$lat,$lng);
);
out center 60;
''';
  }

  static List<RecyclePoint> _parsePoints(String body, double lat, double lng) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];
    return elements.map((element) {
      final item = element as Map<String, dynamic>;
      final tags = (item['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final pointLat = (item['lat'] ?? item['center']?['lat'] ?? lat)
          .toDouble();
      final pointLon = (item['lon'] ?? item['center']?['lon'] ?? lng)
          .toDouble();
      final address = [
        tags['addr:street'],
        tags['addr:city'],
        tags['addr:postcode'],
      ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
      return RecyclePoint(
        id: item['id'].toString(),
        name: (tags['name'] ?? 'Community Recycling Point').toString(),
        address: address.isEmpty ? 'OpenStreetMap recycling location' : address,
        acceptedItems: _acceptedItems(tags),
        openingHours:
            (tags['opening_hours'] ?? 'Check with venue before visiting')
                .toString(),
        latitude: pointLat,
        longitude: pointLon,
        distanceKm: distanceKm(lat, lng, pointLat, pointLon),
      );
    }).toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
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
