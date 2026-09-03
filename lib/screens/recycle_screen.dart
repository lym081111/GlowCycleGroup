import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/beauty_product.dart';
import '../models/recycle_lookup.dart';
import '../models/recycle_point.dart';
import '../services/recycle_service.dart';
import '../theme/app_colors.dart';

/// A live OSM map and point picker. When a finished product is supplied, the
/// final confirmation is the only place that writes its Recycled status.
class RecycleScreen extends StatefulWidget {
  const RecycleScreen({super.key, this.product, this.onRecycled});

  final BeautyProduct? product;
  final Future<void> Function()? onRecycled;

  @override
  State<RecycleScreen> createState() => _RecycleScreenState();
}

class _RecycleScreenState extends State<RecycleScreen> {
  RecycleLookup? _lookup;
  RecyclePoint? _selectedPoint;
  var _searching = false;
  var _confirming = false;

  bool get _isContainerFlow =>
      widget.product != null && widget.onRecycled != null;

  bool get _canConfirm =>
      _isContainerFlow &&
      widget.product!.resolvedStatus(DateTime.now()) == 'Finished' &&
      _selectedPoint != null;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search({bool announce = false}) async {
    if (_searching) {
      return;
    }
    setState(() => _searching = true);
    final position = await RecycleService.currentPosition();
    final result = await RecycleService.fetchRecyclePoints(
      latitude: position?.latitude,
      longitude: position?.longitude,
      forceRefresh: announce,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _lookup = result;
      _selectedPoint = result.points.isEmpty ? null : result.points.first;
      _searching = false;
    });
    if (announce) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorNote ??
                '${result.points.length} recycle point(s) found.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDirections(RecyclePoint point) async {
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

  Future<void> _confirmRecycle() async {
    final product = widget.product;
    final point = _selectedPoint;
    if (product == null || point == null || !_canConfirm || _confirming) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm recycling'),
        content: Text('Mark ${product.name} as recycled at ${point.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I recycled it'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _confirming = true);
    await widget.onRecycled!();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} marked as recycled.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final lookup = _lookup;
    final title = _isContainerFlow ? 'Choose a recycle point' : 'Recycle map';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                : const Icon(Icons.my_location_outlined),
          ),
        ],
      ),
      body: lookup == null
          ? const _SearchingIndicator()
          : lookup.failed || lookup.points.isEmpty
          ? _NoRecyclePoints(
              message:
                  lookup.errorNote ??
                  'No recycling point is mapped near ${lookup.originLabel}.',
              onSearchAgain: () => _search(announce: true),
            )
          : _RecyclePicker(
              lookup: lookup,
              selectedPoint: _selectedPoint,
              product: widget.product,
              canConfirm: _canConfirm,
              confirming: _confirming,
              onSelect: (point) => setState(() => _selectedPoint = point),
              onDirections: _openDirections,
              onConfirm: _confirmRecycle,
            ),
    );
  }
}

class _RecyclePicker extends StatelessWidget {
  const _RecyclePicker({
    required this.lookup,
    required this.selectedPoint,
    required this.product,
    required this.canConfirm,
    required this.confirming,
    required this.onSelect,
    required this.onDirections,
    required this.onConfirm,
  });

  final RecycleLookup lookup;
  final RecyclePoint? selectedPoint;
  final BeautyProduct? product;
  final bool canConfirm;
  final bool confirming;
  final ValueChanged<RecyclePoint> onSelect;
  final Future<void> Function(RecyclePoint point) onDirections;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final focus = selectedPoint ?? lookup.points.first;
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(focus.latitude, focus.longitude),
            initialZoom: lookup.expanded ? 9.5 : 12.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.glowcycle.glowcycle',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lookup.originLatitude, lookup.originLongitude),
                  width: 42,
                  height: 42,
                  child: const _LocationMarker(),
                ),
                for (final point in lookup.points)
                  Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: 48,
                    height: 56,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => onSelect(point),
                      child: _RecycleMarker(
                        selected: point.id == selectedPoint?.id,
                      ),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.36,
          maxChildSize: 0.78,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F1A1C1C),
                  blurRadius: 18,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              children: [
                Align(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nearest mapped recycle points',
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                for (final point in lookup.points)
                  _RecyclePointTile(
                    point: point,
                    selected: point.id == selectedPoint?.id,
                    onTap: () => onSelect(point),
                    onDirections: () => onDirections(point),
                  ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: selectedPoint == null
                        ? null
                        : () => onDirections(selectedPoint!),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Go to recycle point'),
                  ),
                ),
                if (product != null) ...[
                  const SizedBox(height: 10),
                  if (!canConfirm)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Mark this product finished on your Shelf before confirming recycling.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: tertiary, fontSize: 12),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canConfirm && !confirming ? onConfirm : null,
                      child: Text(
                        confirming
                            ? 'Recording recycling...'
                            : 'I recycled this container',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will mark ${product!.name} as Recycled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.56),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecyclePointTile extends StatelessWidget {
  const _RecyclePointTile({
    required this.point,
    required this.selected,
    required this.onTap,
    required this.onDirections,
  });

  final RecyclePoint point;
  final bool selected;
  final VoidCallback onTap;
  final Future<void> Function() onDirections;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? primary : ink.withValues(alpha: 0.08),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${point.distanceKm.toStringAsFixed(1)} km  •  ${point.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.58),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accepts ${point.acceptedItems}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: tertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              selected
                  ? const Icon(Icons.check_circle, color: primary)
                  : IconButton(
                      tooltip: 'Directions',
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_outlined),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecycleMarker extends StatelessWidget {
  const _RecycleMarker({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on,
      size: selected ? 46 : 40,
      color: selected ? primary : tertiary,
      shadows: const [Shadow(color: Colors.black26, blurRadius: 5)],
    );
  }
}

class _LocationMarker extends StatelessWidget {
  const _LocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
      child: Container(
        margin: const EdgeInsets.all(7),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Overpass can take up to ~30s per radius and this screen tries up to three
/// radii, so a bare spinner reads as a freeze well before it resolves.
class _SearchingIndicator extends StatelessWidget {
  const _SearchingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Searching OpenStreetMap for recycling points near you.\n'
              'This can take up to a minute when nothing is mapped close by.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ink, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRecyclePoints extends StatelessWidget {
  const _NoRecyclePoints({required this.message, required this.onSearchAgain});

  final String message;
  final VoidCallback onSearchAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.travel_explore_outlined,
              color: tertiary,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ink, height: 1.35),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onSearchAgain,
              icon: const Icon(Icons.refresh),
              label: const Text('Search again'),
            ),
          ],
        ),
      ),
    );
  }
}
