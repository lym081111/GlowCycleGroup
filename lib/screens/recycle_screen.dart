import 'package:flutter/material.dart';

import '../models/recycle_point.dart';
import '../services/recycle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/layout_widgets.dart';

/// Nearby recycling drop-off points, fetched from the Overpass API.
class RecycleScreen extends StatefulWidget {
  const RecycleScreen({super.key});

  @override
  State<RecycleScreen> createState() => _RecycleScreenState();
}

class _RecycleScreenState extends State<RecycleScreen> {
  late Future<List<RecyclePoint>> _points;

  @override
  void initState() {
    super.initState();
    _points = RecycleService.fetchRecyclePoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby recycling')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const AppHeader(
            title: 'Recycle points',
            subtitle:
                'External endpoint data for responsible packaging disposal.',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_sync_outlined, color: ink),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This screen connects to OpenStreetMap Overpass API and falls back to curated demo points if the endpoint is unavailable.',
                    style: TextStyle(color: ink, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<RecyclePoint>>(
            future: _points,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(34),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final points = snapshot.data ?? RecycleService.fallbackPoints;
              return Column(
                children: points
                    .map(
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
                                    '${point.distanceKm.toStringAsFixed(1)} km from UTAR Kampar reference',
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
