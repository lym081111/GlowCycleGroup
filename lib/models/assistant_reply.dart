import 'beauty_product.dart';

/// A Glow Assistant answer, either returned by Gemini or produced locally by
/// the offline rule engine in [AssistantReply.local].
class AssistantReply {
  AssistantReply({
    required this.message,
    required this.productNames,
    required this.safetyNote,
  });

  final String message;
  final List<String> productNames;
  final String safetyNote;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    return AssistantReply(
      message: (json['message'] ?? '').toString(),
      productNames: ((json['productNames'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
      safetyNote: (json['safetyNote'] ?? '').toString(),
    );
  }

  /// Offline fallback used when Gemini is unavailable or its answer fails
  /// [isSafeFor]. Keeps the assistant usable without a network round trip.
  factory AssistantReply.local(String message, List<BeautyProduct> products) {
    final lower = message.toLowerCase();
    final now = DateTime.now();
    final eyeConcern = _isEyeConcern(lower);
    final active = products
        .where((item) => item.resolvedStatus(now) == 'Safe')
        .toList();
    final gentle = active.where((item) {
      final text =
          '${item.name} ${item.category} ${item.ingredients.join(' ')} ${item.notes}'
              .toLowerCase();
      if (eyeConcern && !_isEyeCompatible(item, text)) {
        return false;
      }
      return text.contains('barrier') ||
          text.contains('ceramide') ||
          text.contains('panthenol') ||
          text.contains('hyaluronic') ||
          text.contains('moistur');
    }).toList();
    final eyeSafeActive = eyeConcern
        ? active
              .where((item) => _isEyeCompatible(item, _productText(item)))
              .toList()
        : active;
    final chosen = gentle.isEmpty
        ? eyeSafeActive.take(2).toList()
        : gentle.take(3).toList();
    if (eyeConcern) {
      final names = chosen.map((item) => item.name).toList();
      final eyeDrops = chosen
          .where((item) => _isEyeDropProduct(_productText(item)))
          .toList();
      final productAdvice = eyeDrops.isNotEmpty
          ? 'You have ${eyeDrops.map((item) => item.name).join(', ')} on your shelf. Use it only as directed on its label, and do not use it if the bottle is expired or contaminated.'
          : names.isEmpty
          ? 'I cannot find a suitable lubricating eye drop or gentle eye-area product on your shelf.'
          : 'The only shelf items worth considering around the eye area are ${names.join(', ')}.';
      return AssistantReply(
        message:
            'Dry or irritated eyes need extra caution. Do not put lip balm, makeup, fragrance, acids, retinoids, vitamin C, or new products in or close to your eyes. $productAdvice Use skincare only on the surrounding skin if the label says it is suitable, and stop if it stings.',
        productNames: names,
        safetyNote:
            'Glow Assistant is not a medical diagnosis. For eye pain, light sensitivity, discharge, swelling, vision changes, or symptoms that persist, seek prompt advice from an optometrist or doctor.',
      );
    }

    final sensitiveConcern = _hasAny(lower, [
      'red',
      'itch',
      'sensitive',
      'irritat',
      'rash',
      '泛红',
      '痒',
      '敏感',
    ]);
    final dryConcern = _hasAny(lower, [
      'dry',
      'dehydrat',
      'tight',
      'flaky',
      'dryness',
      '干燥',
      '紧绷',
    ]);
    final breakoutConcern = _hasAny(lower, [
      'acne',
      'pimple',
      'breakout',
      'blemish',
      'blackhead',
      '痘',
      '粉刺',
    ]);
    final usedIds = <String>{};
    final chosenProducts = <BeautyProduct>[];

    BeautyProduct? pick(Iterable<BeautyProduct> candidates) {
      for (final item in candidates) {
        if (usedIds.add(item.id)) {
          chosenProducts.add(item);
          return item;
        }
      }
      return null;
    }

    final gentleProducts = active.where(
      (item) => !_hasStrongActives(_productText(item)),
    );
    final cleansers = gentleProducts.where(
      (item) => _hasAny(_productText(item), [
        'cleanser',
        'cleanse',
        'face wash',
        'micellar',
      ]),
    );
    final barrierProducts = gentleProducts.where(
      (item) => _hasAny(_productText(item), [
        'moistur',
        'barrier',
        'ceramide',
        'panthenol',
        'hyaluronic',
        'glycerin',
        'centella',
        'squalane',
        'cream',
      ]),
    );
    final acneProducts = active.where(
      (item) => _hasAny(_productText(item), [
        'salicylic',
        'bha',
        'benzoyl',
        'azelaic',
        'niacinamide',
      ]),
    );

    final routine = <String>[];
    if (sensitiveConcern) {
      final cleanser = pick(cleansers);
      final barrier = pick(barrierProducts);
      routine.add(
        cleanser == null
            ? 'Cleanse: use only a gentle cleanser if your skin tolerates it.'
            : 'Cleanse: use ${cleanser.name} with lukewarm water.',
      );
      routine.add(
        barrier == null
            ? 'Support: use a basic fragrance-free moisturiser if you have one.'
            : 'Support: apply ${barrier.name} in a thin layer to support the skin barrier.',
      );
    } else if (breakoutConcern && !dryConcern) {
      final cleanser = pick(cleansers);
      final treatment = pick(acneProducts);
      final barrier = pick(barrierProducts);
      routine.add(
        cleanser == null
            ? 'Cleanse: keep cleansing gentle and do not scrub.'
            : 'Cleanse: start with ${cleanser.name}.',
      );
      routine.add(
        treatment == null
            ? 'Treat: I cannot find a clearly labelled acne treatment on your shelf, so do not introduce several new actives today.'
            : 'Treat: use ${treatment.name} only as directed, and do not layer it with other strong actives.',
      );
      if (barrier != null) {
        routine.add(
          'Support: finish with ${barrier.name} if your skin feels dry.',
        );
      }
    } else {
      final cleanser = pick(cleansers);
      final hydration = pick(barrierProducts);
      routine.add(
        cleanser == null
            ? 'Cleanse: keep this step gentle and brief.'
            : 'Cleanse: start with ${cleanser.name}.',
      );
      routine.add(
        hydration == null
            ? 'Hydrate: use your simplest moisturising product in a thin layer.'
            : 'Hydrate: apply ${hydration.name} while skin is slightly damp.',
      );
    }

    final concernLabel = sensitiveConcern
        ? 'Your message sounds like irritation or sensitivity.'
        : breakoutConcern
        ? 'Your message sounds like a breakout concern.'
        : dryConcern
        ? 'Your message sounds like dehydration or dryness.'
        : 'I will keep the routine low-risk because the concern is not specific yet.';
    final avoid = sensitiveConcern
        ? 'Avoid today: exfoliating acids, retinoids, strong vitamin C, scrubs, fragrance, and trying new products.'
        : breakoutConcern
        ? 'Avoid today: picking, scrubbing, and stacking several acne actives in one routine.'
        : 'Avoid today: layering too many actives at once or using any product that stings.';
    final names = chosenProducts.map((item) => item.name).toList();
    return AssistantReply(
      message:
          'Skin signal: $concernLabel\n\nSuggested routine:\n${routine.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n')}\n\n$avoid',
      productNames: names,
      safetyNote:
          'Glow Assistant is not a medical diagnosis. Seek professional care if symptoms are painful, swollen, infected, or persistent.',
    );
  }

  /// Guard applied to Gemini answers before they reach the user: every named
  /// product must exist on the shelf, and eye concerns must not be answered
  /// with lip, makeup, or active-ingredient products.
  bool isSafeFor(String userMessage, List<BeautyProduct> products) {
    final safeNames = products
        .where((item) => item.resolvedStatus(DateTime.now()) == 'Safe')
        .map((item) => item.name.toLowerCase())
        .toSet();
    if (!productNames.every((name) => safeNames.contains(name.toLowerCase()))) {
      return false;
    }
    if (!_isEyeConcern(userMessage.toLowerCase())) {
      return true;
    }
    final replyText = '$message ${productNames.join(' ')}'.toLowerCase();
    if (RegExp(
      r'\b(?:use|apply|put|try)\s+(?:a\s+|your\s+)?(?:lip|lipstick|lip balm|tint|gloss|mascara|eyeliner)\b',
    ).hasMatch(replyText)) {
      return false;
    }
    final allowedNames = products
        .where(
          (item) =>
              item.resolvedStatus(DateTime.now()) == 'Safe' &&
              _isEyeCompatible(item, _productText(item)),
        )
        .map((item) => item.name.toLowerCase())
        .toSet();
    return productNames.every(
      (name) => allowedNames.contains(name.toLowerCase()),
    );
  }

  static bool _isEyeConcern(String text) {
    return RegExp(
      r'\b(?:eye|eyes|eyelid|under-eye|under eye)\b',
    ).hasMatch(text);
  }

  static String _productText(BeautyProduct item) {
    return '${item.name} ${item.category} ${item.ingredients.join(' ')} ${item.notes}'
        .toLowerCase();
  }

  static bool _isEyeCompatible(BeautyProduct item, String text) {
    if (_isEyeDropProduct(text)) {
      return true;
    }
    if (item.category != 'Skincare') {
      return false;
    }
    return !RegExp(
      r'\b(?:lip|lipstick|lip balm|tint|gloss|mascara|eyeliner|fragrance|perfume|retinol|retinoid|aha|bha|salicylic|glycolic|lactic|vitamin c|ascorbic|scrub|exfoliat)\b',
    ).hasMatch(text);
  }

  static bool _isEyeDropProduct(String text) {
    return RegExp(
      r'\b(?:eye\s*drop|eyedrop|artificial\s*tear|lubricat(?:ing|ion)\s*(?:eye\s*)?drop|ocular\s*lubricant)\b',
    ).hasMatch(text);
  }

  static bool _hasStrongActives(String text) {
    return _hasAny(text, [
      'retinol',
      'retinoid',
      'salicylic',
      'glycolic',
      'lactic',
      'aha',
      'bha',
      'benzoyl',
      'exfoliat',
      'scrub',
      'vitamin c',
      'ascorbic',
    ]);
  }

  static bool _hasAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}
