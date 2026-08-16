import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Five-destination bottom navigation bar for [GlowCycleHome].
class GlowBottomNav extends StatelessWidget {
  const GlowBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Shelf'),
    (Icons.document_scanner_outlined, Icons.document_scanner, 'Scan'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'Assistant'),
    (Icons.savings_outlined, Icons.savings, 'Saver'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: const Border(top: BorderSide(color: outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      // The bar used a fixed 16px bottom padding, which sat underneath the
      // system navigation bar on devices that show one and hid the labels.
      // SafeArea insets the items instead, while the decoration still runs to
      // the bottom edge of the screen.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                _GlowNavItem(
                  icon: _items[i].$1,
                  selectedIcon: _items[i].$2,
                  label: _items[i].$3,
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowNavItem extends StatelessWidget {
  const _GlowNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 13 : 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected ? primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? primary : const Color(0xFF424941),
              size: 23,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? primary : const Color(0xFF424941),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
