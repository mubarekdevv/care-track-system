import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_order_model.dart';

class OrderStatusTimeline extends StatelessWidget {
  final MarketplaceOrder order;

  const OrderStatusTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeIndex = order.trackingStepIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery tracking',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < MarketplaceOrder.trackingSteps.length; i++) ...[
            _TimelineStep(
              title: MarketplaceOrder.trackingSteps[i].$2,
              subtitle: MarketplaceOrder.trackingSteps[i].$3,
              isComplete: i <= activeIndex,
              isActive: i == activeIndex,
              isLast: i == MarketplaceOrder.trackingSteps.length - 1,
              accent: order.statusColor(context),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isComplete;
  final bool isActive;
  final bool isLast;
  final Color accent;
  final bool isDark;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.isActive,
    required this.isLast,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isComplete ? accent : (isDark ? Colors.grey.shade700 : AppTheme.inputBorder);
    final lineColor = isComplete && !isLast ? accent.withValues(alpha: 0.35) : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: isActive ? 22 : 18,
                  height: isActive ? 22 : 18,
                  decoration: BoxDecoration(
                    color: isComplete ? accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: isComplete
                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isComplete
                          ? (isDark ? Colors.white : AppTheme.textPrimary)
                          : (isDark ? Colors.grey[500] : AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
