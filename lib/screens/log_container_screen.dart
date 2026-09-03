import 'package:flutter/material.dart';

import '../models/beauty_product.dart';
import '../theme/app_colors.dart';
import '../widgets/product_cards.dart';
import '../widgets/status_widgets.dart';

/// The empty-container queue. Products first become Finished on the Shelf;
/// only then do they appear here ready to be handed to a recycle point.
class LogContainerScreen extends StatefulWidget {
  const LogContainerScreen({
    super.key,
    required this.products,
    required this.onFindRecyclePoint,
  });

  final List<BeautyProduct> products;
  final Future<bool> Function(BeautyProduct product) onFindRecyclePoint;

  @override
  State<LogContainerScreen> createState() => _LogContainerScreenState();
}

class _LogContainerScreenState extends State<LogContainerScreen> {
  final Set<String> _recycledIds = <String>{};

  Future<void> _findRecyclePoint(BeautyProduct product) async {
    final recycled = await widget.onFindRecyclePoint(product);
    if (recycled && mounted) {
      setState(() => _recycledIds.add(product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final emptyContainers =
        widget.products
            .where((item) => item.resolvedStatus(DateTime.now()) == 'Finished')
            .where((item) => !_recycledIds.contains(item.id))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Log empty containers')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          const Text(
            'Log empty containers',
            style: TextStyle(
              color: ink,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (emptyContainers.isEmpty)
            const _NoEmptyContainers()
          else ...[
            for (final product in emptyContainers)
              _EmptyContainerCard(
                product: product,
                onFindRecyclePoint: () => _findRecyclePoint(product),
              ),
            const SizedBox(height: 4),
            const _ShelfBoundaryNote(),
          ],
        ],
      ),
    );
  }
}

class _EmptyContainerCard extends StatelessWidget {
  const _EmptyContainerCard({
    required this.product,
    required this.onFindRecyclePoint,
  });

  final BeautyProduct product;
  final Future<void> Function() onFindRecyclePoint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 96,
            child: ProductImageMock(product: product, status: 'Finished'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const StatusBadge(status: 'Finished'),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onFindRecyclePoint,
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: const Text('Find recycle point'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoEmptyContainers extends StatelessWidget {
  const _NoEmptyContainers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.07)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: primary, size: 40),
          SizedBox(height: 12),
          Text(
            'No empty containers yet',
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Mark a product finished on your Shelf when it is empty.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tertiary, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ShelfBoundaryNote extends StatelessWidget {
  const _ShelfBoundaryNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.spa_outlined, color: primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Active products stay on your Shelf. Only finished containers appear here.',
              style: TextStyle(color: tertiary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
