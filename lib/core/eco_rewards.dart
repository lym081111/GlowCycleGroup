/// Point values and the rules that keep them meaningful.
///
/// Every award used to be unbounded: finishing a product could be claimed
/// again by editing its status back, the duplicate skip reset whenever its
/// screen was rebuilt, and the no-buy challenge paid out on every tap. Points
/// only ever rose, so a shelf full of expired products scored the same as a
/// well managed one.
class EcoRewards {
  const EcoRewards._();

  static const addProduct = 1;
  static const finishBeforeExpiry = 15;
  static const finishAfterExpiry = 10;
  static const recycleContainer = 15;
  static const avoidDuplicate = 25;
  static const noBuyChallenge = 60;

  /// Days a no-buy challenge must run before it can be claimed.
  static const noBuyChallengeDays = 7;
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
