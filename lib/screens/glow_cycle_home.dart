import 'package:flutter/material.dart';

import '../models/beauty_product.dart';
import '../theme/app_colors.dart';
import '../widgets/glow_bottom_nav.dart';
import 'feature_placeholder_screen.dart';
import 'product_form_screen.dart';

class GlowCycleHome extends StatefulWidget {
  const GlowCycleHome({super.key});

  @override
  State<GlowCycleHome> createState() => _GlowCycleHomeState();
}

class _GlowCycleHomeState extends State<GlowCycleHome> {
  var _selectedIndex = 0;
  final _scannedProducts = <BeautyProduct>[];

  Future<void> _addProduct(BeautyProduct product) async {
    setState(() {
      _scannedProducts.insert(0, product);
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      _LeaderDashboard(
        products: _scannedProducts,
        onScan: () => setState(() => _selectedIndex = 2),
      ),
      const FeaturePlaceholderScreen(
        title: 'Beauty Shelf',
        icon: Icons.inventory_2_outlined,
      ),
      ProductFormScreen(
        onSave: _addProduct,
        closeOnSave: false,
        onSaved: () => setState(() => _selectedIndex = 0),
      ),
      const FeaturePlaceholderScreen(
        title: 'Glow Assistant',
        icon: Icons.chat_bubble_outline,
      ),
      const FeaturePlaceholderScreen(
        title: 'Cycle',
        icon: Icons.autorenew_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GlowCycle',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset('assets/icon/glowcycle_icon.png'),
        ),
      ),
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: GlowBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _LeaderDashboard extends StatelessWidget {
  const _LeaderDashboard({required this.products, required this.onScan});

  final List<BeautyProduct> products;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Smart beauty inventory',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan a product package and review every extracted field before adding it.',
          style: TextStyle(color: ink.withValues(alpha: 0.66), height: 1.4),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onScan,
          icon: const Icon(Icons.document_scanner_outlined),
          label: const Text('Scan a product'),
        ),
        const SizedBox(height: 24),
        Text(
          'Scanned products',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No product has been scanned in this session.'),
            ),
          )
        else
          for (final product in products)
            Card(
              child: ListTile(
                leading: const Icon(Icons.spa_outlined, color: primary),
                title: Text(product.name),
                subtitle: Text('${product.brand} - ${product.category}'),
                trailing: product.scanSource == 'gemini-vision'
                    ? const Icon(Icons.auto_awesome, color: primary)
                    : const Icon(Icons.text_snippet_outlined),
              ),
            ),
      ],
    );
  }
}
