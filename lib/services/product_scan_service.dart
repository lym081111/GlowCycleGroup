import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/constants.dart';
import '../models/product_scan_result.dart';
import 'firebase_bootstrap.dart';

typedef ScanPhotoRef = ({String path, String dataUri});

class ProductScanService {
  Future<ProductScanResult> scan({required List<ScanPhotoRef> photos}) async {
    if (photos.isEmpty) {
      return ProductScanResult.empty();
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final sections = <String>[];
      for (var i = 0; i < photos.length; i++) {
        final recognized = await recognizer.processImage(
          InputImage.fromFilePath(photos[i].path),
        );
        final value = recognized.text.trim();
        if (value.isNotEmpty) {
          sections.add(
            photos.length == 1 ? value : '--- Photo ${i + 1} ---\n$value',
          );
        }
      }

      final ocrText = sections.join('\n\n');
      if (!FirebaseBootstrap.configured) {
        return ProductScanResult.fromOcrHeuristic(ocrText);
      }

      try {
        return await _extractWithGemini(
          ocrText: ocrText,
          imageDataUris: [for (final photo in photos) photo.dataUri],
        );
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Gemini product scan fallback: $error');
        }
        return ProductScanResult.fromOcrHeuristic(ocrText);
      }
    } finally {
      await recognizer.close();
    }
  }

  Future<ProductScanResult> _extractWithGemini({
    required String ocrText,
    required List<String> imageDataUris,
  }) async {
    final dataUriPattern = RegExp(r'^data:([^;]+);base64,(.+)$');
    final imageParts = <InlineDataPart>[];
    for (final uri in imageDataUris) {
      final match = dataUriPattern.firstMatch(uri);
      if (match != null) {
        imageParts.add(
          InlineDataPart(match.group(1)!, base64Decode(match.group(2)!)),
        );
      }
    }
    if (imageParts.isEmpty) {
      throw const FormatException('No valid product photo to scan.');
    }

    final schema = Schema.object(
      properties: {
        'productName': Schema.string(),
        'brand': Schema.string(),
        'category': Schema.enumString(enumValues: productCategories),
        'ingredients': Schema.array(items: Schema.string()),
        'manufactureDate': Schema.string(nullable: true),
        'expiryDate': Schema.string(nullable: true),
        'paoMonths': Schema.integer(nullable: true, minimum: 1, maximum: 60),
        'batchNumber': Schema.string(),
        'confidence': Schema.number(minimum: 0, maximum: 1),
      },
    );
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      generationConfig: GenerationConfig(
        temperature: 0,
        maxOutputTokens: 4096,
        thinkingConfig: ThinkingConfig.withThinkingLevel(
          ThinkingLevel.minimal,
        ),
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
    final prompt = '''
Extract factual product information from these beauty-product package photos.
Use the photos as primary evidence and OCR text only as supporting evidence.

Return only the requested JSON. Never invent unreadable values. Dates must be
ISO yyyy-MM-dd and only returned when their printed meaning is unambiguous.
PAO must come from an opened-jar label such as 6M or 12M. Ingredients must be
individual INCI ingredients, not instructions or marketing claims. Select one
category from the supplied list and use Others when uncertain. Confidence is a
number from 0 to 1.

OCR text:
${ocrText.isEmpty ? '(No readable OCR text.)' : ocrText}
''';
    final response = await model
        .generateContent([
          Content.multi([TextPart(prompt), ...imageParts]),
        ])
        .timeout(Duration(seconds: 25 + (imageParts.length - 1) * 10));
    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw const FormatException('Gemini returned an empty scan.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Gemini returned invalid JSON.');
    }
    return ProductScanResult.fromJson(
      decoded,
      ocrText,
      source: 'gemini-vision',
    );
  }
}
