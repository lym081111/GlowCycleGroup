import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/product_scan_result.dart';
import 'glow_store.dart';

/// One photo to read, as an on-device path for OCR plus its inline data URI
/// for the vision model.
typedef ScanPhotoRef = ({String path, String dataUri});

/// Runs on-device ML Kit OCR over every supplied photo, then hands the
/// combined text and all the images to [GlowStore] for Gemini extraction
/// (or the local heuristic when Gemini is unavailable).
class ProductScanService {
  ProductScanService({required this.store});

  final GlowStore store;

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
        final text = recognized.text.trim();
        if (text.isEmpty) {
          continue;
        }
        // Label each block so the model can tell the front of the package
        // from the ingredient panel on the back.
        sections.add(
          photos.length == 1 ? text : '--- Photo ${i + 1} ---\n$text',
        );
      }
      final combined = sections.join('\n\n');
      if (combined.isEmpty && photos.length == 1) {
        return ProductScanResult.empty();
      }
      return store.extractProductData(
        ocrText: combined,
        imageDataUris: [for (final photo in photos) photo.dataUri],
      );
    } finally {
      await recognizer.close();
    }
  }
}
