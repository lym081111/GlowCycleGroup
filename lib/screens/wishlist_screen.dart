import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/beauty_product.dart';
import '../theme/app_colors.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/product_cards.dart';

/// Duplicate-purchase check: counts what the user already owns in a category
/// before they buy another one.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({
    super.key,
    required this.products,
    required this.onAvoidDuplicate,
  });

  final List<BeautyProduct> products;
  final Future<void> Function(String category) onAvoidDuplicate;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  var _category = 'Makeup';
  var _productName = '';
  var _checked = false;
  var _saved = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final matches = widget.products
        .where(
          (item) =>
              item.category == _category &&
              !['Finished', 'Recycled'].contains(item.resolvedStatus(now)),
        )
        .toList();
    final useSoon = matches
        .where((item) => item.resolvedStatus(now) == 'Use Soon')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist check')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const AppHeader(
            title: 'Think before buying',
            subtitle: 'Check your shelf before a new beauty purchase.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: productCategories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() {
              _category = value ?? 'Makeup';
              _checked = false;
              _saved = false;
            }),
            decoration: const InputDecoration(
              labelText: 'Product category you want to buy',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) => setState(() => _productName = value),
            decoration: const InputDecoration(
              labelText: 'Product name (optional)',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => setState(() => _checked = true),
            icon: const Icon(Icons.search),
            label: const Text('Check inventory'),
          ),
          if (_checked) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: matches.isEmpty ? mint : blush,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    matches.isEmpty
                        ? Icons.check_circle
                        : Icons.lightbulb_outline,
                    color: matches.isEmpty ? sage : brandPink,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    matches.isEmpty
                        ? 'No active $_category products found.'
                        : 'You already have ${matches.length} active $_category product(s).',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    matches.isEmpty
                        ? 'If this purchase is necessary, add it after buying so GlowCycle can track its lifecycle.'
                        : '$useSoon of them are expiring soon. Consider finishing one before buying ${_productName.isEmpty ? 'another item' : _productName}.',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                  if (matches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saved
                          ? null
                          : () async {
                              await widget.onAvoidDuplicate(_category);
                              setState(() => _saved = true);
                            },
                      icon: const Icon(Icons.eco_outlined),
                      label: Text(
                        _saved
                            ? 'Eco points added'
                            : 'I will skip this purchase',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...matches
                .take(4)
                .map(
                  (item) => ProductShelfCard(
                    product: item,
                    compact: true,
                    onTap: () {},
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
