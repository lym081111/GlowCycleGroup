/// A logged sustainable action, such as finishing or recycling a product.
class EcoAction {
  EcoAction({
    required this.id,
    required this.actionType,
    required this.pointsEarned,
    required this.description,
    required this.date,
    this.relatedProductId,
    this.category,
  });

  factory EcoAction.created({
    required String actionType,
    required int pointsEarned,
    required String description,
    String? relatedProductId,
    String? category,
  }) {
    final now = DateTime.now();
    return EcoAction(
      id: now.microsecondsSinceEpoch.toString(),
      actionType: actionType,
      pointsEarned: pointsEarned,
      description: description,
      date: now,
      relatedProductId: relatedProductId,
      category: category,
    );
  }

  final String id;
  final String actionType;

  /// May be negative, for awards that were later reversed.
  final int pointsEarned;
  final String description;
  final DateTime date;
  final String? relatedProductId;

  /// Product category this action concerned, where one applies.
  ///
  /// Recorded so the daily duplicate-skip limit and its reversal can be
  /// checked without parsing [description].
  final String? category;

  /// True when this action happened on the same calendar day as [other].
  bool isSameDayAs(DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType,
    'pointsEarned': pointsEarned,
    'description': description,
    'date': date.toIso8601String(),
    'relatedProductId': relatedProductId,
    'category': category,
  };

  factory EcoAction.fromJson(Map<String, dynamic> json) {
    return EcoAction(
      id: json['id'] as String,
      actionType: json['actionType'] as String,
      pointsEarned: json['pointsEarned'] as int,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      relatedProductId: json['relatedProductId'] as String?,
      category: json['category'] as String?,
    );
  }
}
