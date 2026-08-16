import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/beauty_product.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/product_cards.dart';
import '../widgets/status_widgets.dart';

/// Full record for one product, plus the finish and recycle lifecycle actions.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onFinished,
    required this.onRecycled,
  });

  final BeautyProduct product;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final Future<void> Function() onFinished;
  final Future<void> Function() onRecycled;

  /// Describes where the photo lives.
  ///
  /// [BeautyProduct.imagePath] holds either a Storage download URL or an
  /// inline base64 data URI, and printing the raw value filled the screen
  /// with hundreds of kilobytes of unreadable text.
  static String _photoLabel(BeautyProduct product) {
    final path = product.imagePath;
    if (path.startsWith('http')) {
      return 'Synced to your cloud storage';
    }
    if (path.startsWith('data:image')) {
      final kb = (path.length * 3 / 4 / 1024).round();
      return 'Saved on this device (about $kb KB)';
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product detail'),
        actions: [
          IconButton(
            tooltip: 'Edit product',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete product',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete product?'),
                  content: Text(
                    '${product.name} will be removed from your local inventory.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await onDelete();
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ink.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Show the photo the user actually took when there is one;
                    // ProductImageMock falls back to the category illustration
                    // for products added without a picture.
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: product.imagePath.isEmpty
                          ? CategoryIcon(category: product.category, size: 58)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ProductImageMock(
                                product: product,
                                status: status,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ink,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            product.brand,
                            style: TextStyle(
                              color: ink.withValues(alpha: 0.62),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatusBadge(status: status),
                const SizedBox(height: 18),
                DetailRow(label: 'Category', value: product.category),
                DetailRow(
                  label: 'Purchase date',
                  value: dateFormat.format(product.purchaseDate),
                ),
                DetailRow(
                  label: 'Opening date',
                  value: dateFormat.format(product.openingDate),
                ),
                if (product.manufactureDate != null)
                  DetailRow(
                    label: 'MFG date',
                    value: dateFormat.format(product.manufactureDate!),
                  ),
                DetailRow(
                  label: 'Expiry date',
                  value: dateFormat.format(product.expiryDate),
                ),
                DetailRow(
                  label: 'Days remaining',
                  value: product.daysRemaining(now).toString(),
                ),
                DetailRow(
                  label: 'Expiry duration',
                  value: '${product.expiryMonths} months',
                ),
                if (product.batchNumber.isNotEmpty)
                  DetailRow(label: 'Batch', value: product.batchNumber),
                if (product.price != null)
                  DetailRow(
                    label: 'Price',
                    value: 'RM ${product.price!.toStringAsFixed(2)}',
                  ),
                if (product.ingredients.isNotEmpty)
                  DetailRow(
                    label: 'Ingredients',
                    value: product.ingredients.join(', '),
                  ),
                if (product.scanSource != 'manual')
                  DetailRow(
                    label: 'AI scan',
                    value:
                        '${product.scanSource} - ${(product.scanConfidence * 100).round()}%',
                  ),
                if (product.imagePath.isNotEmpty)
                  DetailRow(label: 'Photo', value: _photoLabel(product)),
                if (product.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Notes',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.notes,
                    style: const TextStyle(color: ink, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: ['Finished', 'Recycled'].contains(status)
                ? null
                : () async {
                    await onFinished();
                    if (context.mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as finished'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: status == 'Recycled'
                ? null
                : () async {
                    await onRecycled();
                    if (context.mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.recycling),
            label: const Text('Mark container recycled'),
          ),
        ],
      ),
    );
  }
}
