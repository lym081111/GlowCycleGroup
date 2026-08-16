import 'recycle_point.dart';

/// The outcome of a recycle-point search.
///
/// Results are always live OpenStreetMap data. There is deliberately no
/// curated fallback: an area with nothing mapped is a real finding about open
/// data coverage, and inventing places to fill the screen would misrepresent
/// both the service and the area.
class RecycleLookup {
  const RecycleLookup({
    required this.points,
    required this.originLabel,
    required this.radiusKm,
    this.errorNote,
  });

  /// Recycling points found, nearest first. Empty when the area has none
  /// mapped, or when the search could not complete.
  final List<RecyclePoint> points;

  /// Human-readable description of the search centre.
  final String originLabel;

  /// How far out the search reached.
  final int radiusKm;

  /// Set only when the service could not be reached, which is different from
  /// the service answering with nothing.
  final String? errorNote;

  bool get failed => errorNote != null;

  /// True when the search succeeded and the area genuinely has nothing mapped.
  bool get isUnmapped => !failed && points.isEmpty;
}
