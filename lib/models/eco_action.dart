/// A logged sustainable action, such as finishing or recycling a product.
class EcoAction {
  EcoAction({
    required this.id,
    required this.actionType,
    required this.pointsEarned,
    required this.description,
    required this.date,
    this.relatedProductId,
  });

  factory EcoAction.created({
    required String actionType,
    required int pointsEarned,
    required String description,
    String? relatedProductId,
  }) {
    final now = DateTime.now();
    return EcoAction(
      id: now.microsecondsSinceEpoch.toString(),
      actionType: actionType,
      pointsEarned: pointsEarned,
      description: description,
      date: now,
      relatedProductId: relatedProductId,
    );
  }

  final String id;
  final String actionType;
  final int pointsEarned;
  final String description;
  final DateTime date;
  final String? relatedProductId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType,
    'pointsEarned': pointsEarned,
    'description': description,
    'date': date.toIso8601String(),
    'relatedProductId': relatedProductId,
  };

  factory EcoAction.fromJson(Map<String, dynamic> json) {
    return EcoAction(
      id: json['id'] as String,
      actionType: json['actionType'] as String,
      pointsEarned: json['pointsEarned'] as int,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      relatedProductId: json['relatedProductId'] as String?,
    );
  }
}
