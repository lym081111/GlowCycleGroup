import 'package:intl/intl.dart';

/// Product categories offered throughout the app.
const productCategories = [
  'Skincare',
  'Makeup',
  'Haircare',
  'Bodycare',
  'Fragrance',
  'Others',
];

/// Lifecycle states a user may set manually on a product.
///
/// `Safe`, `Use Soon`, and `Expired` are never set by hand: they are derived
/// from the opening date and PAO duration by [BeautyProduct.resolvedStatus].
const editableStatuses = ['Unopened', 'Opened', 'Finished', 'Recycled'];

/// Default Period After Opening (PAO) duration, in months, per category.
const categoryExpiryMonths = {
  'Skincare': 12,
  'Makeup': 12,
  'Haircare': 18,
  'Bodycare': 12,
  'Fragrance': 24,
  'Others': 12,
};

final dateFormat = DateFormat('yyyy-MM-dd');
