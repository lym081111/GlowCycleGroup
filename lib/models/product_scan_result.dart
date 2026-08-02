import '../core/constants.dart';
import '../core/helpers.dart';

/// Structured fields extracted from a product package, either by Gemini
/// vision or by the local OCR heuristic fallback.
class ProductScanResult {
  ProductScanResult({
    required this.productName,
    required this.brand,
    required this.category,
    required this.ingredients,
    required this.manufactureDate,
    required this.expiryDate,
    required this.paoMonths,
    required this.batchNumber,
    required this.confidence,
    required this.source,
    required this.rawTextPreview,
  });

  final String productName;
  final String brand;
  final String category;
  final List<String> ingredients;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final int? paoMonths;
  final String batchNumber;
  final double confidence;
  final String source;
  final String rawTextPreview;

  factory ProductScanResult.empty() {
    return ProductScanResult(
      productName: '',
      brand: '',
      category: 'Skincare',
      ingredients: const [],
      manufactureDate: null,
      expiryDate: null,
      paoMonths: null,
      batchNumber: '',
      confidence: 0,
      source: 'ocr-empty',
      rawTextPreview: 'No readable text detected.',
    );
  }

  factory ProductScanResult.fromJson(
    Map<String, dynamic> json,
    String fallbackText, {
    String source = 'gemini',
  }) {
    return ProductScanResult(
      productName: (json['productName'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      category: productCategories.contains(json['category'])
          ? json['category'].toString()
          : 'Skincare',
      ingredients: _cleanIngredients((json['ingredients'] as List?) ?? []),
      manufactureDate: parseOptionalDate(json['manufactureDate']),
      expiryDate: parseOptionalDate(json['expiryDate']),
      paoMonths: num.tryParse((json['paoMonths'] ?? '').toString())?.round(),
      batchNumber: (json['batchNumber'] ?? '').toString(),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0).clamp(0, 1),
      source: source,
      rawTextPreview: _previewText(fallbackText),
    );
  }

  /// Best-effort parsing used when Gemini is unavailable, so a scan still
  /// produces something the user can correct by hand.
  factory ProductScanResult.fromOcrHeuristic(String text) {
    final lines = text
        .split(RegExp(r'\n+'))
        .map((item) => item.trim())
        .where((item) => item.length > 2)
        .toList();
    final ingredients = _extractIngredients(text);
    final pao = RegExp(
      r'(\d{1,2})\s*M\b',
      caseSensitive: false,
    ).firstMatch(text);
    final batch = RegExp(
      r'(?:batch|lot|bn|b/no)\s*[:#-]?\s*([A-Z0-9-]{3,})',
      caseSensitive: false,
    ).firstMatch(text);
    return ProductScanResult(
      productName: lines.length > 1
          ? lines[1]
          : (lines.isEmpty ? '' : lines[0]),
      brand: lines.isEmpty ? '' : lines.first,
      category: _guessCategory(text),
      ingredients: ingredients,
      manufactureDate: _extractDate(text, ['mfg', 'mfd', 'manufactured']),
      expiryDate: _extractDate(text, ['exp', 'expiry', 'expires']),
      paoMonths: pao == null ? null : int.tryParse(pao.group(1)!),
      batchNumber: batch?.group(1) ?? '',
      confidence: ingredients.isEmpty ? 0.46 : 0.62,
      source: 'local-ocr',
      rawTextPreview: _previewText(text),
    );
  }

  static List<String> _extractIngredients(String text) {
    final match = RegExp(
      r'(?:ingredients?|inci)\s*[:\-]?\s*([\s\S]{8,900})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return const [];
    }
    final lines = (match.group(1) ?? '').split(RegExp(r'\n+'));
    final ingredientLines = <String>[];
    for (final line in lines) {
      if (RegExp(
        r'^(?:directions?|how to use|warning|caution|made in|manufactured|mfg|mfd|exp|expiry|batch|lot|net\s*(?:wt|weight|content))',
        caseSensitive: false,
      ).hasMatch(line.trim())) {
        break;
      }
      ingredientLines.add(line);
    }
    return _cleanIngredients(
      parseIngredients(ingredientLines.join(', ')),
    ).take(40).toList();
  }

  static List<String> _cleanIngredients(Iterable<dynamic> values) {
    final seen = <String>{};
    final cleaned = <String>[];
    for (final value in values) {
      final ingredient = value
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final normalized = ingredient.toLowerCase();
      if (ingredient.length < 2 ||
          ingredient.length > 80 ||
          normalized.contains('ingredient') ||
          normalized.contains('directions') ||
          normalized.contains('warning') ||
          !RegExp(r'[a-zA-Z]').hasMatch(ingredient) ||
          !seen.add(normalized)) {
        continue;
      }
      cleaned.add(ingredient);
    }
    return cleaned;
  }

  static DateTime? _extractDate(String text, List<String> labels) {
    final labelPattern = labels.join('|');
    final match = RegExp(
      '(?:$labelPattern)\\s*[:\\-]?\\s*(\\d{1,2}[./-]\\d{1,2}[./-]\\d{2,4}|\\d{4}[./-]\\d{1,2}[./-]\\d{1,2})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    return _parseLooseDate(match.group(1)!);
  }

  static DateTime? _parseLooseDate(String raw) {
    final parts = raw.split(RegExp(r'[./-]')).map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((item) => item == null)) {
      return null;
    }
    var first = parts[0]!;
    final second = parts[1]!;
    var third = parts[2]!;
    if (first > 1900) {
      return DateTime.tryParse(
        '${first.toString().padLeft(4, '0')}-${second.toString().padLeft(2, '0')}-${third.toString().padLeft(2, '0')}',
      );
    }
    if (third < 100) {
      third += 2000;
    }
    return DateTime.tryParse(
      '${third.toString().padLeft(4, '0')}-${second.toString().padLeft(2, '0')}-${first.toString().padLeft(2, '0')}',
    );
  }

  static String _guessCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('lip') ||
        lower.contains('foundation') ||
        lower.contains('mascara')) {
      return 'Makeup';
    }
    if (lower.contains('shampoo') || lower.contains('conditioner')) {
      return 'Haircare';
    }
    if (lower.contains('body') || lower.contains('lotion')) {
      return 'Bodycare';
    }
    if (lower.contains('parfum') || lower.contains('fragrance')) {
      return 'Fragrance';
    }
    return 'Skincare';
  }

  static String _previewText(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 180) {
      return compact;
    }
    return '${compact.substring(0, 180)}...';
  }
}
