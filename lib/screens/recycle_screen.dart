import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recycle_lookup.dart';
import '../models/recycle_point.dart';
import '../services/recycle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/layout_widgets.dart';

/// Nearby recycling drop-off points, searched around the device's location
/// when it is available and the UTAR Kampar reference otherwise.
class RecycleScreen extends StatefulWidget {
  const RecycleScreen({super.key});

  @override
  State<RecycleScreen> createState() => _RecycleScreenState();
}

class _RecycleScreenState extends State<RecycleScreen> {
  RecycleLookup? _lookup;
  var _searching = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  /// Opens the point in Google Maps, or whatever handles map links.
  ///
  /// Coordinates are used rather than the address text, because most OSM
  /// entries here carry no address and a name alone would not resolve.
  Future<void> _openInMaps(RecyclePoint point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${point.latitude},${point.longitude}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No app on this device can open map links.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Runs the lookup and reports the outcome.
  ///
  /// A repeat search usually returns the same places, so without [announce]
  /// the refresh button looked inert even though it had worked.
  Future<void> _search({bool announce = false}) async {
    if (_searching) {
      return;
    }
    setState(() => _searching = true);
    final position = await RecycleService.currentPosition();
    final result = await RecycleService.fetchRecyclePoints(
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _lookup = result;
      _searching = false;
    });
    if (announce) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorNote ??
                'Search complete: ${result.points.length} point(s) '
                    'within ${result.radiusKm} km.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby recycling'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Searching...' : 'Search again',
            onPressed: _searching ? null : () => _search(announce: true),
            icon: _searching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final lookup = _lookup;
          if (lookup == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 14),
                    Text('Finding recycling points near you...'),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              const AppHeader(
                title: 'Recycle points',
                subtitle:
                    'Live OpenStreetMap data for responsible packaging disposal.',
              ),
              const SizedBox(height: 14),
              _SourceBanner(lookup: lookup),
              const SizedBox(height: 16),
              if (lookup.isUnmapped) const _UnmappedFinding(),
              ...lookup.points.map(
                (point) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.place_outlined, color: sage),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                point.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          point.address,
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.74),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        InfoPill(
                          icon: Icons.recycling,
                          text: point.acceptedItems,
                        ),
                        const SizedBox(height: 8),
                        InfoPill(
                          icon: Icons.schedule,
                          text: point.openingHours,
                        ),
                        const SizedBox(height: 8),
                        InfoPill(
                          icon: Icons.social_distance,
                          text:
                              '${point.distanceKm.toStringAsFixed(1)} km from ${lookup.originLabel}',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openInMaps(point),
                            icon: const Icon(
                              Icons.directions_outlined,
                              size: 18,
                            ),
                            label: const Text('Open in Google Maps'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Says where the search ran and what it returned.
class _SourceBanner extends StatelessWidget {
  const _SourceBanner({required this.lookup});

  final RecycleLookup lookup;

  @override
  Widget build(BuildContext context) {
    final ok = !lookup.failed;
    final count = lookup.points.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? mint : blush,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: ok ? primary : brandPink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !ok
                      ? 'Search unavailable'
                      : lookup.expanded
                      ? 'None near you'
                      : 'Live OpenStreetMap data',
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lookup.errorNote ??
                      (lookup.expanded
                          ? 'No recycling point is mapped within '
                                '${lookup.nearRadiusKm} km of ${lookup.originLabel}. '
                                'These are the $count nearest in the country, up to '
                                '${lookup.radiusKm} km away.'
                          : '$count point(s) found within ${lookup.radiusKm} km of '
                                '${lookup.originLabel}, via the Overpass API.'),
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.72),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reports an empty search as the finding it is.
///
/// Nothing mapped nearby is a fact about open-data coverage, not a failure of
/// the app, and inventing places to fill the screen would hide it.
class _UnmappedFinding extends StatelessWidget {
  const _UnmappedFinding();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.travel_explore_outlined, color: secondary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nothing mapped here yet',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The search worked; this area simply has no recycling point '
            'recorded in OpenStreetMap. Coverage across Malaysia is uneven and '
            'concentrated in the larger cities, so rural areas often return '
            'nothing at all.',
            style: TextStyle(color: ink.withValues(alpha: 0.74), height: 1.35),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'You can change this: adding a real drop-off point to '
              'openstreetmap.org puts it on the map for everyone, including '
              'this app.',
              style: TextStyle(
                color: ink.withValues(alpha: 0.8),
                height: 1.3,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
