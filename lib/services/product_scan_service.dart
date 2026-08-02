import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/product_scan_result.dart';
import 'glow_store.dart';

/// Runs on-device ML Kit OCR, then hands the text and photo to [GlowStore]
/// for Gemini extraction (or the local heuristic when Gemini is unavailable).
class ProductScanService {
  ProductScanService({required this.store});

  final GlowStore store;

  Future<ProductScanResult> scan({
    required String imagePath,
    required String imageDataUri,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final text = recognized.text.trim();
      if (text.isEmpty) {
        return ProductScanResult.empty();
      }
      return store.extractProductData(
        ocrText: text,
        imageDataUri: imageDataUri,
      );
    } finally {
      await recognizer.close();
    }
  }
}
