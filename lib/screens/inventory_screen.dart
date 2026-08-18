import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/beauty_product.dart';
import '../theme/app_colors.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/product_cards.dart';

/// Shelf tab: search, category and status filters over the whole inventory.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<BeautyProduct> products;
  final ValueChanged<BeautyProduct> onProductTap;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  var _query = '';
  var _category = 'All';
  var _status = 'All';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = widget.products.where((product) {
      final text = '${product.name} ${product.brand}'.toLowerCase();
      final matchesQuery = text.contains(_query.toLowerCase());
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final matchesStatus =
          _status == 'All' || product.resolvedStatus(now) == _status;
      return matchesQuery && matchesCategory && matchesStatus;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // In All Items, keep active products easy to browse and send lifecycle
    // records to the bottom without hiding them. A product is still sorted by
    // its original added date within its own section.
    const pastStatuses = {'Expired', 'Finished', 'Recycled'};
    final isAllItemsView = _category == 'All' && _status == 'All';
    final activeProducts = filtered
        .where((product) => !pastStatuses.contains(product.resolvedStatus(now)))
        .toList();
    final pastProducts = filtered
        .where((product) => pastStatuses.contains(product.resolvedStatus(now)))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const AppHeader(
          title: 'My Beauty Shelf',
          subtitle:
              'Your newest additions, with past items kept out of the way.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ink.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              const Icon(Icons.south_outlined, color: primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${filtered.length} item(s)',
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: ' - newest added first',
                        style: TextStyle(color: ink.withValues(alpha: 0.62)),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search your shelf',
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in ['All', ...productCategories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _category == category,
                    label: Text(category == 'All' ? 'All Items' : category),
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: primaryContainer,
                    backgroundColor: surfaceHigh,
                    checkmarkColor: primary,
                    labelStyle: TextStyle(
                      color: _category == category
                          ? primary
                          : const Color(0xFF424941),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: primary,
                  ),
                  label: const Text('Smart Sort'),
                  backgroundColor: primaryContainer,
                  labelStyle: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                  onPressed: () => setState(() => _status = 'Use Soon'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Every value resolvedStatus can return needs a chip, or those
              // products match no filter but "All" and look missing.
              for (final status in [
                'All',
                'Safe',
                'Unopened',
                'Use Soon',
                'Expired',
                'Finished',
                'Recycled',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _status == status,
                    label: Text(status),
                    onSelected: (_) => setState(() => _status = status),
                    selectedColor: secondaryContainer,
                    backgroundColor: surfaceLow,
                    labelStyle: TextStyle(
                      color: _status == status
                          ? secondary
                          : const Color(0xFF424941),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products found',
            message:
                'Try another filter or add a product to your beauty shelf.',
          )
        else if (isAllItemsView) ...[
          if (activeProducts.isNotEmpty)
            BeautyShelfView(
              products: activeProducts,
              onProductTap: widget.onProductTap,
            ),
          if (pastProducts.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: ink.withValues(alpha: 0.1))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'PAST ITEMS',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: ink.withValues(alpha: 0.1))),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Expired, finished and recycled products are kept here for your records.',
              style: TextStyle(
                color: ink.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: 0.68,
              child: BeautyShelfView(
                products: pastProducts,
                onProductTap: widget.onProductTap,
              ),
            ),
          ],
        ] else
          BeautyShelfView(
            products: filtered,
            onProductTap: widget.onProductTap,
          ),
      ],
    );
  }
}
