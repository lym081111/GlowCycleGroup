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
    }).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const AppHeader(
          title: 'My Beauty Shelf',
          subtitle: 'Curated by expiry, category, and what deserves attention.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF5F0), Color(0xFFE7F2E7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: primary, size: 18),
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
                        text: ' - sorted by what to finish first',
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
              for (final status in [
                'All',
                'Safe',
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
        else
          BeautyShelfView(
            products: filtered,
            onProductTap: widget.onProductTap,
          ),
      ],
    );
  }
}
