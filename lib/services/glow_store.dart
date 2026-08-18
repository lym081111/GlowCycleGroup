import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/app_data.dart';
import '../models/app_user.dart';
import '../models/assistant_chat_message.dart';
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

  /// Explains, in debug builds, why an AI call was never attempted.
  ///
  /// Without this, "Firebase was unavailable so we skipped Gemini" and
  /// "Gemini was called and failed" both surface as the same silent fallback.
  void _logAiSkipped(String feature) {
    if (!kDebugMode) {
      return;
    }
    final reason = !FirebaseBootstrap.configured
        ? 'Firebase did not initialise: ${FirebaseBootstrap.error ?? 'unknown error'}'
        : 'signed in with the offline demo login, not Firebase Auth';
    debugPrint('$feature skipped, no Gemini call made - $reason');
  }

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

  CollectionReference<Map<String, dynamic>> get _chatsRef => FirebaseFirestore
      .instance
      .collection('users')
      .doc(user.uid)
      .collection('chats');

  /// Why the last [load] could not reach Firestore, or null if it did.
  ///
  /// The UI reports this so a shelf served from local storage is never
  /// mistaken for a synced one.
  String? lastLoadError;

  /// Firestore reads are bounded, so a denied rule or a dead connection
  /// surfaces as a fallback rather than an indefinite spinner.
  static const _firestoreTimeout = Duration(seconds: 15);

  /// Loads the user's shelf, preferring Firestore and falling back to local
  /// storage.
  ///
  /// A Firestore failure — denied rules, App Check rejection, no connectivity
  /// — must not propagate: an unhandled exception here would leave the home
  /// screen stuck on its loading indicator with nothing to act on.
  Future<AppData> load() async {
    lastLoadError = null;
    if (_useFirebase) {
      try {
        await _migrateLocalDataIfNeeded();
        final productSnapshot = await _productsRef
            .orderBy('updatedAt', descending: true)
            .get()
            .timeout(_firestoreTimeout);
        final actionSnapshot = await _actionsRef
            .orderBy('date', descending: true)
            .get()
            .timeout(_firestoreTimeout);
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
      } catch (exception) {
        lastLoadError = _describeLoadError(exception);
        if (kDebugMode) {
          debugPrint('Firestore load failed, using local data: $exception');
        }
        return _loadLocal();
      }
    }
    return _loadLocal();
  }

  /// Turns a Firestore exception into something a user can act on.
  static String _describeLoadError(Object exception) {
    final text = exception.toString();
    if (text.contains('permission-denied')) {
      return 'Firestore rules are rejecting this account. Showing local data.';
    }
    if (text.contains('unavailable') || exception is TimeoutException) {
      return 'Could not reach Firestore. Showing local data.';
    }
    return 'Cloud sync unavailable. Showing local data.';
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
    required List<String> imageDataUris,
  }) async {
    if (_useFirebase) {
      try {
        return await _scanProductWithGemini(
          ocrText: ocrText,
          imageDataUris: imageDataUris,
        );
      } catch (exception) {
        if (kDebugMode) {
          debugPrint('Gemini product scan fallback: $exception');
        }
        return ProductScanResult.fromOcrHeuristic(ocrText);
      }
    }
    _logAiSkipped('Product scan');
    return ProductScanResult.fromOcrHeuristic(ocrText);
  }

  Future<ProductScanResult> _scanProductWithGemini({
    required String ocrText,
    required List<String> imageDataUris,
  }) async {
    final pattern = RegExp(r'^data:([^;]+);base64,(.+)$');
    final imageParts = <InlineDataPart>[];
    for (final uri in imageDataUris) {
      final match = pattern.firstMatch(uri);
      if (match == null) {
        continue;
      }
      imageParts.add(
        InlineDataPart(match.group(1)!, base64Decode(match.group(2)!)),
      );
    }
    if (imageParts.isEmpty) {
      throw const FormatException('No valid product photo to scan.');
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
        // A full INCI list runs to 40+ ingredients. The previous 900-token
        // ceiling truncated the JSON mid-array, which threw during decode and
        // silently dropped the whole scan to the regex fallback.
        maxOutputTokens: 4096,
        // Extraction is transcription, not reasoning. Minimal thinking keeps
        // the token budget for output and cuts scan latency.
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.minimal),
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
    );
    final prompt =
        '''
You extract facts from a beauty-product package. Use the photos and OCR text
together; the photos are primary when OCR characters are unclear.

${imageParts.length == 1 ? 'One photo is attached.' : '${imageParts.length} photos of the same product are attached, in the order the user took them. They show different faces of the package: the front usually carries the product name and brand, while the back or side carries the ingredient list, batch code, PAO symbol, and dates. Merge them into one record and never report the same product twice.'}

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

OCR text read from the photos:
${ocrText.isEmpty ? '(No readable OCR text.)' : ocrText}
''';
    final response = await model
        .generateContent([
          Content.multi([TextPart(prompt), ...imageParts]),
        ])
        .timeout(Duration(seconds: 25 + (imageParts.length - 1) * 10));
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

  /// Answers a skincare question using the user's own shelf.
  ///
  /// [history] is the conversation so far, oldest first, so follow-up
  /// questions keep their context. Gemini receives one correction attempt if
  /// it names a product that is not on the user's usable shelf.
  Future<AssistantReply> askAssistant({
    required String message,
    required List<BeautyProduct> products,
    List<AssistantChatMessage> history = const [],
  }) async {
    final now = DateTime.now();
    final offeredProducts = products
        .where((item) => item.isRecommendable(now))
        .map((item) => item.toAssistantJson())
        .toList();

    if (_useFirebase) {
      try {
        final reply = await _askGemini(
          message: message,
          inventory: offeredProducts,
          history: history,
        );
        if (reply.isGroundedInInventory(products)) {
          return reply;
        }
        if (kDebugMode) {
          debugPrint(
            'Gemini Assistant reply requested an inventory correction; '
            'recommended ${reply.productNames}',
          );
        }
        final correctedReply = await _askGemini(
          message: message,
          inventory: offeredProducts,
          history: history,
          groundingRetry: true,
        );
        if (correctedReply.isGroundedInInventory(products)) {
          return correctedReply;
        }
        return AssistantReply.local(safetyFallback: true);
      } catch (exception) {
        if (kDebugMode) {
          debugPrint('Gemini Assistant fallback: $exception');
        }
        return AssistantReply.local(
          quotaLimited: _isGeminiQuotaError(exception),
        );
      }
    }
    _logAiSkipped('Glow Assistant');
    return AssistantReply.local();
  }

  static bool _isGeminiQuotaError(Object exception) {
    final text = exception.toString().toLowerCase();
    return text.contains('quota exceeded') ||
        text.contains('resource_exhausted') ||
        text.contains('free_tier_requests') ||
        text.contains('rate limit');
  }

  /// Number of prior turns replayed to Gemini. Enough for a follow-up to make
  /// sense without letting the prompt grow without bound.
  static const _historyTurnLimit = 8;

  Future<AssistantReply> _askGemini({
    required String message,
    required List<Map<String, dynamic>> inventory,
    required List<AssistantChatMessage> history,
    bool groundingRetry = false,
  }) async {
    final responseSchema = Schema.object(
      properties: {
        'message': Schema.string(),
        'productNames': Schema.array(items: Schema.string()),
        'safetyNote': Schema.string(),
      },
    );
    final retryInstruction = groundingRetry
        ? '''
This is a correction pass. Your previous answer named a product that was not
an exact match for the current shelf. Re-evaluate the same concern from the
inventory below and return only real, exact product names in productNames.
'''
        : '';
    final systemInstruction =
        '''
You are Glow Assistant, an attentive beauty-inventory assistant. Give
practical, personalised skincare guidance based on the shelf inventory supplied
with each question.

Reason privately before answering: identify the concern and body area, assess
the available products using their user-reviewed productType, ingredients,
notes, category, and expiry status, then decide whether any product actually
fits. Do not treat a broad category alone as proof that a product suits a
particular concern or body area.

Requirements:
- Reply with the required JSON only.
- productNames must contain only exact product names from the supplied
  inventory that you actively recommend. Never invent, rename, or recommend a
  product that is not listed.
- The inventory already excludes expired, finished, and recycled items.
- If shelf data is ambiguous, say what information is missing instead of
  guessing a product's purpose.
- Give a simple routine with 2 to 4 clearly numbered steps when appropriate.
- Do not diagnose, claim to treat disease, or make medical guarantees.
- If symptoms are severe, painful, swollen, infected, involve vision changes,
  or persist, advise a doctor, dermatologist, or optometrist.
- In message, do not mention a named product unless it also appears exactly in
  productNames. Keep the tone supportive and concise.
- Earlier turns are provided for context. Resolve follow-up questions against
  what was already discussed.
$retryInstruction
''';
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      systemInstruction: Content.system(systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.2,
        // Raised from 500: thinking tokens share this budget, and truncated
        // output decodes as invalid JSON, which silently drops the answer to
        // the offline rule engine.
        maxOutputTokens: 2048,
        thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
    );

    final recentHistory = history.length > _historyTurnLimit
        ? history.sublist(history.length - _historyTurnLimit)
        : history;
    final contents = <Content>[
      for (final turn in recentHistory)
        if (turn.role == 'user')
          Content.text(turn.text)
        else
          Content.model([TextPart(turn.text)]),
      // Inventory travels with the current question so the model always
      // reasons over the shelf as it is right now, not as it was ten turns ago.
      Content.text('''
Shelf inventory JSON: ${jsonEncode(inventory)}

User concern: ${jsonEncode(message)}
'''),
    ];
    final response = await model
        .generateContent(contents)
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
    required DateTime createdAt,
    String? safetyNote,
    bool fromFallback = false,
    bool safetyFallback = false,
    bool quotaLimited = false,
  }) async {
    if (!_useFirebase) {
      return;
    }
    await _chatsRef.add({
      'role': role,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      if (safetyNote != null && safetyNote.isNotEmpty) 'safetyNote': safetyNote,
      'fromFallback': fromFallback,
      'safetyFallback': safetyFallback,
      'quotaLimited': quotaLimited,
    });
  }

  /// Returns the current 24-hour conversation and removes older turns.
  ///
  /// Firestore is the shared source of truth for authenticated users, so a
  /// conversation survives navigating away from the Assistant tab and also
  /// follows the user to another signed-in device.
  Future<List<AssistantChatMessage>> loadRecentChatMessages() async {
    if (!_useFirebase) {
      return const [];
    }
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final cutoffTimestamp = Timestamp.fromDate(cutoff);
    try {
      final snapshots = await Future.wait([
        _chatsRef
            .where('createdAt', isGreaterThanOrEqualTo: cutoffTimestamp)
            .orderBy('createdAt')
            .get()
            .timeout(_firestoreTimeout),
        _chatsRef
            .where('createdAt', isLessThan: cutoffTimestamp)
            .limit(400)
            .get()
            .timeout(_firestoreTimeout),
      ]);
      final recent = snapshots[0];
      final expired = snapshots[1];

      if (expired.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final document in expired.docs) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }

      return recent.docs.map((document) {
        final data = document.data();
        final timestamp = data['createdAt'];
        return AssistantChatMessage(
          role: data['role'] as String? ?? 'assistant',
          text: data['text'] as String? ?? '',
          createdAt: timestamp is Timestamp
              ? timestamp.toDate()
              : DateTime.now(),
          safetyNote: data['safetyNote'] as String?,
          fromFallback: data['fromFallback'] as bool? ?? false,
          safetyFallback: data['safetyFallback'] as bool? ?? false,
          quotaLimited: data['quotaLimited'] as bool? ?? false,
        );
      }).toList();
    } catch (exception) {
      if (kDebugMode) {
        debugPrint('Assistant history could not be loaded: $exception');
      }
      return const [];
    }
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
