import 'dart:convert';
import 'dart:typed_data';

String? requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required';
  }
  return null;
}

DateTime? parseOptionalDate(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

List<String> parseIngredients(String value) {
  return value
      .split(RegExp(r'[,;\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

/// Decodes an inline `data:image/...;base64,...` URI into raw bytes.
///
/// Returns null for remote URLs and for anything that is not a data URI, so
/// callers can fall back to [Image.network] or a placeholder illustration.
Uint8List? decodeProductImage(String value) {
  if (!value.startsWith('data:image')) {
    return null;
  }
  final commaIndex = value.indexOf(',');
  if (commaIndex == -1 || commaIndex == value.length - 1) {
    return null;
  }
  try {
    return base64Decode(value.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}
