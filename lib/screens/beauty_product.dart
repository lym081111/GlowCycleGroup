import '../core/helpers.dart';

/// One item on the user's beauty shelf.
class BeautyProduct {
  BeautyProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.productType = '',
    required this.purchaseDate,
    required this.openingDate,
    required this.expiryMonths,
    required this.status,
    required this.imagePath,
    required this.notes,
    required this.ingredients,
    this.manufactureDate,
    this.directExpiryDate,
    this.batchNumber = '',
    this.price,
    this.scanConfidence = 0,
    this.scanSource = 'manual',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String brand;
  final String category;

  /// A user-reviewed, specific label such as "Moisturizer" or "Eye drops".
  /// Categories are intentionally broad, so Glow Assistant uses this to
  /// distinguish products within a category.
  final String productType;
  final DateTime purchaseDate;
  final DateTime openingDate;
  final int expiryMonths;
  final String status;
  final String imagePath;
  final String notes;
  final List<String> ingredients;
  final DateTime? manufactureDate;
  final DateTime? directExpiryDate;
  final String batchNumber;
  final double? price;
  final double scanConfidence;
  final String scanSource;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// A printed expiry date always wins; otherwise expiry is derived from the
  /// opening date plus the PAO duration.
  DateTime get expiryDate =>
      directExpiryDate ??
      DateTime(
        openingDate.year,
        openingDate.month + expiryMonths,
        openingDate.day,
      );

  int daysRemaining(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// How many days before expiry a product starts warning the user.
  ///
  /// The proposal specifies Safe as more than 60 days remaining and Use Soon
  /// as 1-60 days, items expiring today included.
  static const useSoonWindowDays = 60;

  /// Combines the stored lifecycle state with the calendar to produce the
  /// status shown in the UI.
  String resolvedStatus(DateTime now) {
    if (status == 'Finished' || status == 'Recycled') {
      return status;
    }
    final days = daysRemaining(now);
    if (days < 0) {
      return 'Expired';
    }
    if (days <= useSoonWindowDays) {
      return 'Use Soon';
    }
    if (status == 'Unopened') {
      return 'Unopened';
    }
    return 'Safe';
  }

  /// Whether Glow Assistant may recommend this product.
  ///
  /// Anything still usable qualifies, including items expiring soon: nudging
  /// the user to finish those first is the point of the app. Only expired,
  /// finished, and recycled items are excluded.
  ///
  /// This is the single definition shared by the prompt that builds the
  /// inventory and the guard that validates the reply, so the two can never
  /// disagree about what was on offer.
  bool isRecommendable(DateTime now) {
    const excluded = {'Expired', 'Finished', 'Recycled'};
    return !excluded.contains(resolvedStatus(now));
  }

  /// Whether this item is explicitly suitable for a dry-skin hydration step.
  /// A typed product type takes precedence; keyword inference supports older
  /// products created before the Product type field existed.
  bool get isHydratingProduct {
    final text = '$name $productType $category ${ingredients.join(' ')} $notes'
        .toLowerCase();
    // Eye lubricants hydrate the eye surface, not facial skin or lips.
    if (RegExp(
      r'\b(?:eye\s*drop|eyedrop|artificial\s*tear|ocular\s*lubricant|systane)\b',
    ).hasMatch(text)) {
      return false;
    }
    return text.contains('moistur') ||
        text.contains('hydration') ||
        text.contains('hyaluronic') ||
        text.contains('ceramide') ||
        text.contains('panthenol') ||
        text.contains('glycerin') ||
        text.contains('centella') ||
        text.contains('squalane') ||
        text.contains('barrier');
  }

  /// A user-supplied product type gives Gemini useful context without forcing
  /// the app to decide which product belongs in a routine.
  List<String> get assistantTags => [
    if (productType.trim().isNotEmpty) 'type:${productType.trim()}',
  ];

  BeautyProduct copyWith({String? status, DateTime? updatedAt}) {
    return BeautyProduct(
      id: id,
      name: name,
      brand: brand,
      category: category,
      productType: productType,
      purchaseDate: purchaseDate,
      openingDate: openingDate,
      expiryMonths: expiryMonths,
      status: status ?? this.status,
      imagePath: imagePath,
      notes: notes,
      ingredients: ingredients,
      manufactureDate: manufactureDate,
      directExpiryDate: directExpiryDate,
      batchNumber: batchNumber,
      price: price,
      scanConfidence: scanConfidence,
      scanSource: scanSource,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'productType': productType,
    'purchaseDate': purchaseDate.toIso8601String(),
    'openingDate': openingDate.toIso8601String(),
    'expiryMonths': expiryMonths,
    'status': status,
    'imagePath': imagePath,
    'notes': notes,
    'ingredients': ingredients,
    'manufactureDate': manufactureDate?.toIso8601String(),
    'directExpiryDate': directExpiryDate?.toIso8601String(),
    'batchNumber': batchNumber,
    'price': price,
    'scanConfidence': scanConfidence,
    'scanSource': scanSource,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// The trimmed shape sent to Gemini, so the prompt never carries ids,
  /// photos, or prices.
  Map<String, dynamic> toAssistantJson() => {
    'name': name,
    'brand': brand,
    'category': category,
    'productType': productType,
    'status': resolvedStatus(DateTime.now()),
    'expiryDate': expiryDate.toIso8601String(),
    'ingredients': ingredients,
    'notes': notes,
    'assistantTags': assistantTags,
  };

  factory BeautyProduct.fromJson(Map<String, dynamic> json) {
    return BeautyProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String,
      productType: json['productType'] as String? ?? '',
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      openingDate: DateTime.parse(json['openingDate'] as String),
      expiryMonths: json['expiryMonths'] as int,
      status: json['status'] as String,
      imagePath: json['imagePath'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      ingredients: ((json['ingredients'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
      manufactureDate: parseOptionalDate(json['manufactureDate']),
      directExpiryDate: parseOptionalDate(json['directExpiryDate']),
      batchNumber: json['batchNumber'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      scanConfidence: (json['scanConfidence'] as num?)?.toDouble() ?? 0,
      scanSource: json['scanSource'] as String? ?? 'manual',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
