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
    required this.onFinished,
    required this.onRecycle,
  });

  final List<BeautyProduct> products;
  final ValueChanged<BeautyProduct> onProductTap;
  final Future<void> Function(BeautyProduct product) onFinished;
  final Future<void> Function(BeautyProduct product) onRecycle;

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
    const archivedStatuses = {'Expired', 'Finished', 'Recycled'};
    final filtered = widget.products.where((product) {
      // The normal Shelf stays focused on products that can still be used.
      // Archived records remain available through their explicit status chips.
      if (_status == 'All' &&
          archivedStatuses.contains(product.resolvedStatus(now))) {
        return false;
      }
      final text = '${product.name} ${product.brand}'.toLowerCase();
      final matchesQuery = text.contains(_query.toLowerCase());
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final matchesStatus =
          _status == 'All' || product.resolvedStatus(now) == _status;
      return matchesQuery && matchesCategory && matchesStatus;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const AppHeader(title: 'My Beauty Shelf'),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search your shelf',
          ),
        ),
        const SizedBox(height: 10),
        _EdgeFade(
          child: SingleChildScrollView(
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
        ),
        const SizedBox(height: 10),
        _EdgeFade(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
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
            onFinished: widget.onFinished,
            onRecycle: widget.onRecycle,
          ),
      ],
    );
  }
}

/// Fades the trailing edge of a horizontally scrolling row, so a chip cut
/// off at the screen edge reads as "more to scroll" rather than a rendering
/// glitch.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0, 0.9, 1],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
