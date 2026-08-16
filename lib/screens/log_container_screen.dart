import 'package:flutter/material.dart';

import '../core/eco_rewards.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../theme/app_colors.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/status_widgets.dart';

/// Marks products finished or their containers recycled, in one place.
///
/// Both are the app's core eco actions, yet reaching them meant opening the
/// shelf, a product, and its detail screen. Several can be logged here in a
/// row without leaving.
class LogContainerScreen extends StatefulWidget {
  const LogContainerScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onFinished,
    required this.onRecycled,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
  final Future<void> Function(BeautyProduct product) onFinished;
  final Future<void> Function(BeautyProduct product) onRecycled;

  @override
  State<LogContainerScreen> createState() => _LogContainerScreenState();
}

class _LogContainerScreenState extends State<LogContainerScreen> {
  /// Ids acted on during this visit.
  ///
  /// The product list is a snapshot taken when this route was pushed, so it
  /// will not reflect changes made here. Tracking them locally keeps the rows
  /// honest without closing the screen after every tap.
  final _finished = <String>{};
  final _recycled = <String>{};

  bool _isFinished(BeautyProduct product, DateTime now) =>
      _finished.contains(product.id) ||
      product.resolvedStatus(now) == 'Finished';

  bool _isRecycled(BeautyProduct product, DateTime now) =>
      _recycled.contains(product.id) ||
      product.resolvedStatus(now) == 'Recycled';

  bool _alreadyPaid(String actionType, String productId) {
    return widget.actions.any(
      (item) =>
          item.actionType == actionType && item.relatedProductId == productId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // A finished product still has a container to recycle, so only fully
    // recycled ones drop off this list.
    final loggable =
        widget.products.where((item) => !_isRecycled(item, now)).toList()..sort(
          (a, b) => a.daysRemaining(now).compareTo(b.daysRemaining(now)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Log empty container')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          const AppHeader(
            title: 'Finished something?',
            subtitle:
                'Mark a product used up, and log its container once you have '
                'recycled it.',
          ),
          const SizedBox(height: 16),
          if (loggable.isEmpty)
            const EmptyState(
              icon: Icons.recycling,
              title: 'Nothing left to log',
              message:
                  'Every product on your shelf has already been finished and recycled.',
            )
          else
            ...loggable.map(
              (product) => _LoggableRow(
                product: product,
                finished: _isFinished(product, now),
                finishPaid: _alreadyPaid(
                  EcoActionTypes.finishProduct,
                  product.id,
                ),
                recyclePaid: _alreadyPaid(
                  EcoActionTypes.recycleContainer,
                  product.id,
                ),
                onFinish: () async {
                  await widget.onFinished(product);
                  if (mounted) {
                    setState(() => _finished.add(product.id));
                  }
                },
                onRecycle: () async {
                  await widget.onRecycled(product);
                  if (mounted) {
                    setState(() => _recycled.add(product.id));
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LoggableRow extends StatelessWidget {
  const _LoggableRow({
    required this.product,
    required this.finished,
    required this.finishPaid,
    required this.recyclePaid,
    required this.onFinish,
    required this.onRecycle,
  });

  final BeautyProduct product;
  final bool finished;
  final bool finishPaid;
  final bool recyclePaid;
  final Future<void> Function() onFinish;
  final Future<void> Function() onRecycle;

  @override
  Widget build(BuildContext context) {
    final status = product.resolvedStatus(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIcon(category: product.category, size: 42),
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
                        color: ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: finished ? 'Finished' : status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: finished ? null : onFinish,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    finished
                        ? 'Finished'
                        : finishPaid
                        ? 'Finish'
                        : 'Finish +${EcoRewards.finishBeforeExpiry}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRecycle,
                  icon: const Icon(Icons.recycling, size: 18),
                  label: Text(
                    recyclePaid
                        ? 'Recycle'
                        : 'Recycle +${EcoRewards.recycleContainer}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (finishPaid || recyclePaid) ...[
            const SizedBox(height: 8),
            Text(
              'Points for this product have already been earned.',
              style: TextStyle(
                color: ink.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
