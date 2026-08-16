import 'recycle_point.dart';

/// The outcome of a recycle-point search, including where it searched from
/// and whether the results are live.
///
/// The screen previously could not tell live OpenStreetMap data from the
/// curated fallback, so it always claimed the endpoint was unavailable even
/// when the real cause was an empty result set.
class RecycleLookup {
  const RecycleLookup({
    required this.points,
    required this.isLive,
    required this.originLabel,
    this.note,
  });

  /// Curated records used when the search returns nothing usable.
  factory RecycleLookup.fallback({
    required List<RecyclePoint> points,
    required String originLabel,
    required String note,
  }) {
    return RecycleLookup(
      points: points,
      isLive: false,
      originLabel: originLabel,
      note: note,
    );
  }

  final List<RecyclePoint> points;

  /// True when [points] came from OpenStreetMap rather than the fallback.
  final bool isLive;

  /// Human-readable description of the search centre.
  final String originLabel;

  /// Why the fallback was used, when it was.
  final String? note;
}
