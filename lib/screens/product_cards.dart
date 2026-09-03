import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/helpers.dart';
import '../models/beauty_product.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'status_widgets.dart';

/// Short label describing how much life a product has left.
String productShelfLabel(BeautyProduct product, String status, DateTime now) {
  if (status == 'Use Soon') {
    return 'Expiring Soon';
  }
  if (status == 'Expired') {
    return 'Expired';
  }
  if (status == 'Finished') {
    return 'Finished';
  }
  if (status == 'Recycled') {
    return 'Recycled';
  }
  final days = product.daysRemaining(now);
  final months = (days / 30).ceil();
  if (months <= 1) {
    return '$days days left';
  }
  return '$months months left';
}

/// Full-width lifecycle cards keep the product actions visible without hiding
/// them behind an overflow menu.
class BeautyShelfView extends StatelessWidget {
  const BeautyShelfView({
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final product in products)
          LifecycleProductCard(
            product: product,
            onTap: () => onProductTap(product),
            onFinished: () => onFinished(product),
            onRecycle: () => onRecycle(product),
          ),
      ],
    );
  }
}

/// The approved Shelf card: image and product information above two lifecycle
/// actions, so users can finish or start the recycle flow in one tap.
class LifecycleProductCard extends StatelessWidget {
  const LifecycleProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onFinished,
    required this.onRecycle,
  });

  final BeautyProduct product;
  final VoidCallback onTap;
  final Future<void> Function() onFinished;
  final Future<void> Function() onRecycle;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    final isFinished = status == 'Finished';
    final isRecycled = status == 'Recycled';
    final canFinish = !isFinished && !isRecycled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 86,
                      height: 112,
                      child: ProductImageMock(product: product, status: status),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.brand.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink.withValues(alpha: 0.46),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StatusPill(
                            label: productShelfLabel(product, status, now),
                            status: status,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Expires ${dateFormat.format(product.expiryDate)}',
                            style: TextStyle(
                              color: ink.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: canFinish ? onFinished : null,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(isFinished ? 'Finished' : 'Finish'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isRecycled ? null : onRecycle,
                        icon: const Icon(Icons.recycling, size: 18),
                        label: Text(isRecycled ? 'Recycled' : 'Recycle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Square shelf tile with photo, name, status pill, and a life-used bar.
class BentoProductCard extends StatefulWidget {
  const BentoProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final BeautyProduct product;
  final VoidCallback onTap;

  @override
  State<BentoProductCard> createState() => _BentoProductCardState();
}

class _BentoProductCardState extends State<BentoProductCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    final statusAccent = statusColor(status);
    final totalDays = max(
      1,
      product.expiryDate.difference(product.openingDate).inDays,
    );
    final usedDays = now
        .difference(product.openingDate)
        .inDays
        .clamp(0, totalDays);
    final progress = usedDays / totalDays;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ink.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: statusAccent.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ProductImageMock(product: product, status: status),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.48),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      color: ink.withValues(alpha: 0.42),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                StatusPill(
                  label: productShelfLabel(product, status, now),
                  status: status,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    color: statusAccent,
                    backgroundColor: surfaceHigh,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Product photo, falling back to a remote image and then to a drawn bottle.
class ProductImageMock extends StatelessWidget {
  const ProductImageMock({
    super.key,
    required this.product,
    required this.status,
  });

  final BeautyProduct product;
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = categoryPalette(product.category);
    final accent = statusColor(status);
    final imageBytes = decodeProductImage(product.imagePath);
    if (imageBytes != null) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    if (product.imagePath.startsWith('http')) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Image.network(
          product.imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) =>
              Icon(categoryIcon(product.category), color: accent, size: 40),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: palette.first.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      // The bottle is drawn on a fixed canvas and scaled to whatever space
      // the card gives it. Laid out directly, its 92px height overflowed
      // shorter cards and the cap and badge sat at the wrong heights.
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  categoryIcon(product.category),
                  color: Colors.white.withValues(alpha: 0.54),
                  size: 24,
                ),
              ),
              Container(
                width: 50,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 2,
                  ),
                ),
              ),
              Positioned(
                top: 33,
                child: Container(
                  width: 30,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              Positioned(
                bottom: 42,
                child: Container(
                  width: 38,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    categoryIcon(product.category),
                    color: accent,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal product row used by the saver and wishlist screens.
class ProductShelfCard extends StatelessWidget {
  const ProductShelfCard({
    super.key,
    required this.product,
    required this.onTap,
    this.compact = false,
  });

  final BeautyProduct product;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    final days = product.daysRemaining(now);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cocoa.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: brandPink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              CategoryIcon(category: product.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ink,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.brand} • ${product.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink.withValues(alpha: 0.62)),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Expires ${dateFormat.format(product.expiryDate)} • $days days left',
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.62),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

/// Illustrated shelf tile.
///
/// Currently unreferenced; kept as the alternative shelf presentation.
class ShelfProductTile extends StatefulWidget {
  const ShelfProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  final BeautyProduct product;
  final VoidCallback onTap;

  @override
  State<ShelfProductTile> createState() => _ShelfProductTileState();
}

class _ShelfProductTileState extends State<ShelfProductTile> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = widget.product.resolvedStatus(now);
    final days = widget.product.daysRemaining(now);
    final progress = (1 - (days / (widget.product.expiryMonths * 30))).clamp(
      0.0,
      1.0,
    );

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 18,
                  margin: const EdgeInsets.only(top: 126),
                  decoration: BoxDecoration(
                    color: cocoa.withValues(alpha: 0.18),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                ),
                ProductBottleIllustration(
                  category: widget.product.category,
                  status: status,
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                border: Border.all(color: cocoa.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.58),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: progress,
                      color: statusColor(status),
                      backgroundColor: blush,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawn bottle used by [ShelfProductTile].
class ProductBottleIllustration extends StatelessWidget {
  const ProductBottleIllustration({
    super.key,
    required this.category,
    required this.status,
  });

  final String category;
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = categoryPalette(category);
    final statusAccent = statusColor(status);
    return SizedBox(
      height: 144,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 82,
            height: 112,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ink.withValues(alpha: 0.18), width: 2),
              boxShadow: [
                BoxShadow(
                  color: palette.last.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 96,
            child: Container(
              width: 42,
              height: 34,
              decoration: BoxDecoration(
                color: palette.first,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ink.withValues(alpha: 0.18),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            child: Container(
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                categoryIcon(category),
                color: statusAccent,
                size: 22,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: 20,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: statusAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
