import 'package:flutter/material.dart';

import '../../core/constants/trust_badges.dart';
import '../../core/theme/app_theme.dart';

/// Trust badges with tap-to-learn explanations.
class WelcomeTrustSection extends StatelessWidget {
  final bool isDark;

  const WelcomeTrustSection({super.key, required this.isDark});

  void _showBadgeInfo(BuildContext context, TrustBadgeInfo badge) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: badge.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(badge.icon, color: badge.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      badge.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                badge.summary,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                badge.detail,
                style: TextStyle(
                  height: 1.55,
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Trusted by thousands of families and educators',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a badge to learn what it means',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[600] : AppTheme.textSecondary.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final badge in TrustBadges.all)
              _TrustChip(
                badge: badge,
                isDark: isDark,
                onTap: () => _showBadgeInfo(context, badge),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final TrustBadgeInfo badge;
  final bool isDark;
  final VoidCallback onTap;

  const _TrustChip({
    required this.badge,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badge.icon, size: 15, color: badge.accent),
              const SizedBox(width: 6),
              Text(
                badge.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[200] : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
