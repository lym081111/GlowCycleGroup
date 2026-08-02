import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/app_data.dart';
import '../models/app_user.dart';
import '../models/assistant_reply.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/product_scan_result.dart';
import 'firebase_bootstrap.dart';

/// Per-user persistence and AI gateway.
///
/// Signed-in Firebase users read and write Cloud Firestore; everyone else
/// (and any Firebase user whose write fails) falls back to SharedPreferences,
/// so the shelf stays usable offline.
class GlowStore {
  GlowStore({required this.user});

  final AppUser user;

  static const _productsKey = 'glowcycle_products';
  static const _actionsKey = 'glowcycle_actions';
  static const _migrationKey = 'glowcycle_firestore_migrated';

  bool get _useFirebase => user.isFirebaseUser && FirebaseBootstrap.configured;

  String get _localProductsKey => '${_productsKey}_${user.uid}';
  String get _localActionsKey => '${_actionsKey}_${user.uid}';

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('products');

  CollectionReference<Map<String, dynamic>> get _actionsRef => FirebaseFirestore
      .instance
      .collection('users')
      .doc(user.uid)
      .collection('actions');

  Future<AppData> load() async {
    if (_useFirebase) {
      await _migrateLocalDataIfNeeded();
      final productSnapshot = await _productsRef
          .orderBy('updatedAt', descending: true)
          .get();
      final actionSnapshot = await _actionsRef
          .orderBy('date', descending: true)
          .get();
      final products = productSnapshot.docs
          .map((doc) => BeautyProduct.fromJson(doc.data()))
          .toList();
      final actions = actionSnapshot.docs
          .map((doc) => EcoAction.fromJson(doc.data()))
          .toList();
      if (products.isEmpty) {
        final seeded = _seedProducts();
        await save(seeded, actions);
        return AppData(products: seeded, actions: actions);
      }
      return AppData(products: products, actions: actions);
    }
    return _loadLocal();
  }

  Future<AppData> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final productRaw =
        prefs.getString(_localProductsKey) ?? prefs.getString(_productsKey);
    final actionRaw =
        prefs.getString(_localActionsKey) ?? prefs.getString(_actionsKey);
    final products = productRaw == null
        ? _seedProducts()
        : (jsonDecode(productRaw) as List)
              .map(
                (item) => BeautyProduct.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    final actions = actionRaw == null
        ? <EcoAction>[]
        : (jsonDecode(actionRaw) as List)
              .map((item) => EcoAction.fromJson(item as Map<String, dynamic>))
              .toList();
    if (productRaw == null) {
      await save(products, actions);
    }
    return AppData(products: products, actions: actions);
  }

  Future<void> save(
    List<BeautyProduct> products,
    List<EcoAction> actions,
  ) async {
    if (_useFirebase) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final currentProducts = await _productsRef.get();
        final currentActions = await _actionsRef.get();
        final productIds = products.map((item) => item.id).toSet();
        final actionIds = actions.map((item) => item.id).toSet();

        for (final doc in currentProducts.docs) {
          if (!productIds.contains(doc.id)) {
            batch.delete(doc.reference);
          }
        }
        for (final doc in currentActions.docs) {
          if (!actionIds.contains(doc.id)) {
            batch.delete(doc.reference);
          }
        }
        for (final product in products) {
          batch.set(_productsRef.doc(product.id), product.toJson());
        }
        for (final action in actions) {
          batch.set(_actionsRef.doc(action.id), action.toJson());
        }
        await batch.commit();
        return;
      } catch (_) {
        // Keep the user's shelf usable while Firebase rules or connectivity are unavailable.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localProductsKey,
      jsonEncode(products.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      _localActionsKey,
      jsonEncode(actions.map((item) => item.toJson()).toList()),
    );
  }

  /// Uploads an inline data-URI photo to Firebase Storage.
  ///
  /// Returns an empty string when Firebase is unavailable or the upload
  /// fails, in which case the caller keeps the original data URI.
  Future<String> uploadProductPhoto({
    required String productId,
    required String dataUri,
  }) async {
    if (!_useFirebase || !dataUri.startsWith('data:image')) {
      return '';
    }
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1) {
      return '';
    }
    try {
      final bytes = base64Decode(dataUri.substring(commaIndex + 1));
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('product_photos')
          .child('$productId.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    } catch (_) {
      return '';
    }
  }

  Future<ProductScanResult> extractProductData({
    required String ocrText,
    required String imageDataUri,
  }) async {
    if (_useFirebase) {
      try {
        return await _scanProductWithGemini(
          ocrText: ocrText,
          imageDataUri: imageDataUri,
        );
      } catch (exception) {
        if (kDebugMode) {
          debugPrint('Gemini product scan fallback: $exception');
        }
        return ProductScanResult.fromOcrHeuristic(ocrText);
      }
    }
    return ProductScanResult.fromOcrHeuristic(ocrText);
  }

  Future<ProductScanResult> _scanProductWithGemini({
    required String ocrText,
    required String imageDataUri,
  }) async {
    final dataUri = RegExp(
      r'^data:([^;]+);base64,(.+)$',
    ).firstMatch(imageDataUri);
    if (dataUri == null) {
      throw const FormatException('The product photo is not a valid image.');
    }

    final responseSchema = Schema.object(
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
        maxOutputTokens: 900,
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
    );
    final prompt =
        '''
You extract facts from a beauty-product package. Use the photo and OCR text
together; the photo is primary when OCR characters are unclear.

Return the requested JSON only. Follow these rules exactly:
- Extract only text that is visibly present. Never invent a brand, ingredient,
  batch number, manufacturing date, expiry date, or PAO value.
- For dates, return ISO yyyy-MM-dd only when the printed label makes the date
  unambiguous; otherwise return null. Do not calculate an expiry date from PAO.
- Extract PAO only from an opened-jar label such as 6M, 12M, or 24M; otherwise
  return null.
- Ingredients must be individual INCI ingredients, not instructions, warnings,
  marketing claims, or a guessed ingredient list. Use [] when no ingredient
  list is visible.
- Select a category only from the supplied category list. Use Others when the
  package type cannot be confidently classified.
- productName and brand may be empty strings when unreadable.
- confidence must reflect the reliability of the visible evidence, from 0 to 1.

OCR text from this image:
${ocrText.isEmpty ? '(No readable OCR text.)' : ocrText}
''';
    final response = await model
        .generateContent([
          Content.multi([
            TextPart(prompt),
            InlineDataPart(dataUri.group(1)!, base64Decode(dataUri.group(2)!)),
          ]),
        ])
        .timeout(const Duration(seconds: 25));
    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw const FormatException('Gemini returned an empty product scan.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Gemini returned an invalid product scan.');
    }
    return ProductScanResult.fromJson(
      decoded,
      ocrText,
      source: 'gemini-vision',
    );
  }

  Future<AssistantReply> askAssistant({
    required String message,
    required List<BeautyProduct> products,
  }) async {
    final activeProducts = products
        .where(
          (item) => ![
            'Expired',
            'Finished',
            'Recycled',
          ].contains(item.resolvedStatus(DateTime.now())),
        )
        .map((item) => item.toAssistantJson())
        .toList();

    if (_useFirebase) {
      try {
        final reply = await _askGemini(
          message: message,
          inventory: activeProducts,
        );
        return reply.isSafeFor(message, products)
            ? reply
            : AssistantReply.local(message, products);
      } catch (exception) {
        if (kDebugMode) {
          debugPrint('Gemini Assistant fallback: $exception');
        }
        return AssistantReply.local(message, products);
      }
    }
    return AssistantReply.local(message, products);
  }

  Future<AssistantReply> _askGemini({
    required String message,
    required List<Map<String, dynamic>> inventory,
  }) async {
    final responseSchema = Schema.object(
      properties: {
        'message': Schema.string(),
        'productNames': Schema.array(items: Schema.string()),
        'safetyNote': Schema.string(),
      },
    );
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 500,
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
    );
    final prompt =
        '''
You are Glow Assistant, a cautious beauty inventory helper. Give practical,
short skincare guidance based only on the user's Safe Shelf inventory below.

User concern: ${jsonEncode(message)}
Safe Shelf inventory JSON: ${jsonEncode(inventory)}

Rules:
- Reply with the required JSON only.
- productNames must contain only exact product names from Safe Shelf that you
  actively recommend. Never invent, rename, or recommend a product not listed.
- Do not recommend expired, finished, recycled, or unknown products.
- Give a simple routine with 2 to 4 clearly numbered steps when appropriate.
- Do not diagnose, claim to treat disease, or make medical guarantees.
- If symptoms are severe, painful, swollen, infected, involve vision changes,
  or persist, advise a doctor, dermatologist, or optometrist.
- For eye concerns: never recommend lip products, makeup, fragrance, acids,
  retinoids, vitamin C, or unlabelled skincare in or near the eye. Recommend an
  eye drop only when an exact shelf item is clearly an eye drop/lubricant.
- If no suitable shelf item exists, say so honestly and give low-risk general
  guidance without naming a product the user does not own.
- In message, do not mention a named product unless it also appears exactly in
  productNames. Keep the tone supportive and concise.
''';
    final response = await model
        .generateContent([Content.text(prompt)])
        .timeout(const Duration(seconds: 20));
    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw const FormatException('Gemini returned an empty response.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Gemini returned an invalid response.');
    }
    return AssistantReply.fromJson(decoded);
  }

  Future<void> saveChatMessage({
    required String role,
    required String text,
  }) async {
    if (!_useFirebase) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .add({
          'role': role,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Copies any shelf saved before Firebase login into Firestore, once.
  Future<void> _migrateLocalDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_migrationKey}_${user.uid}';
    if (prefs.getBool(key) ?? false) {
      return;
    }
    final existing = await _productsRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      await prefs.setBool(key, true);
      return;
    }
    final localProducts = prefs.getString(_productsKey);
    final localActions = prefs.getString(_actionsKey);
    if (localProducts == null && localActions == null) {
      await prefs.setBool(key, true);
      return;
    }
    final products = localProducts == null
        ? <BeautyProduct>[]
        : (jsonDecode(localProducts) as List)
              .map(
                (item) => BeautyProduct.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    final actions = localActions == null
        ? <EcoAction>[]
        : (jsonDecode(localActions) as List)
              .map((item) => EcoAction.fromJson(item as Map<String, dynamic>))
              .toList();
    if (products.isNotEmpty || actions.isNotEmpty) {
      await save(products, actions);
    }
    await prefs.setBool(key, true);
  }

  /// Demo shelf shown to a brand-new account so the UI is never empty.
  List<BeautyProduct> _seedProducts() {
    final now = DateTime.now();
    return [
      BeautyProduct(
        id: 'seed-serum',
        name: 'Vitamin Glow Serum',
        brand: 'LumiLab',
        category: 'Skincare',
        purchaseDate: now.subtract(const Duration(days: 80)),
        openingDate: now.subtract(const Duration(days: 330)),
        expiryMonths: 12,
        status: 'Opened',
        imagePath: '',
        notes: 'Use at night before moisturizer.',
        ingredients: const ['Vitamin C', 'Hyaluronic Acid', 'Panthenol'],
        manufactureDate: null,
        directExpiryDate: null,
        batchNumber: '',
        price: 89,
        scanConfidence: 0,
        scanSource: 'seed',
        createdAt: now,
        updatedAt: now,
      ),
      BeautyProduct(
        id: 'seed-lip',
        name: 'Rose Cream Lip Tint',
        brand: 'Petal Muse',
        category: 'Makeup',
        purchaseDate: now.subtract(const Duration(days: 40)),
        openingDate: now.subtract(const Duration(days: 20)),
        expiryMonths: 18,
        status: 'Opened',
        imagePath: '',
        notes: 'Everyday shade.',
        ingredients: const ['Shea Butter', 'Rosehip Oil'],
        manufactureDate: null,
        directExpiryDate: null,
        batchNumber: '',
        price: 42,
        scanConfidence: 0,
        scanSource: 'seed',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
