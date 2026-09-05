/// Point values and the rules that keep them meaningful.
///
/// Every award used to be unbounded: finishing a product could be claimed
/// again by editing its status back, the duplicate skip reset whenever its
/// screen was rebuilt, and the no-buy challenge paid out on every tap. Points
/// only ever rose, so a shelf full of expired products scored the same as a
/// well managed one.
class EcoRewards {
  const EcoRewards._();

  static const rulesVersion = 2;
  static const addProduct = 1;
  static const finishBeforeExpiry = 10;
  static const finishAfterExpiry = 0;
  static const recycleContainer = 15;
  static const avoidDuplicate = 5;
  static const noBuyChallenge = 20;

  /// Days a no-buy challenge must run before it can be claimed.
  static const noBuyChallengeDays = 7;

  /// Converts actions saved before the assignment-aligned rules into the
  /// current score. Unknown action types retain their stored value so a future
  /// feature cannot silently erase points during an upgrade.
  static int normalizeLegacyAction({
    required String actionType,
    required String description,
    required int storedPoints,
  }) {
    switch (actionType) {
      case EcoActionTypes.addProduct:
        return addProduct;
      case EcoActionTypes.finishProduct:
        return description.toLowerCase().contains('before expiry')
            ? finishBeforeExpiry
            : finishAfterExpiry;
      case EcoActionTypes.recycleContainer:
        return recycleContainer;
      case EcoActionTypes.avoidDuplicate:
        return avoidDuplicate;
      case EcoActionTypes.duplicateReversed:
        return -avoidDuplicate;
      case EcoActionTypes.noBuyStarted:
        return 0;
      case EcoActionTypes.noBuyCompleted:
        return noBuyChallenge;
      default:
        return storedPoints;
    }
  }
}

/// Action type strings, shared so the award rules and the badge rules cannot
/// drift apart on a typo.
class EcoActionTypes {
  const EcoActionTypes._();

  static const addProduct = 'Add product';
  static const finishProduct = 'Finish product';
  static const recycleContainer = 'Recycle container';
  static const avoidDuplicate = 'Avoid duplicate';

  /// Reverses an [avoidDuplicate] award when the user buys into that category
  /// anyway on the same day.
  static const duplicateReversed = 'Duplicate skip reversed';

  static const noBuyStarted = 'No-buy challenge started';
  static const noBuyCompleted = 'No-buy challenge';
}
