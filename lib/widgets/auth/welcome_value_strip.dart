import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class WelcomeValueStrip extends StatelessWidget {
  final bool isDark;

  const WelcomeValueStrip({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.family_restroom_rounded, 'Care', Color(0xFF4A90E2)),
      (Icons.school_rounded, 'Learn', Color(0xFF7ED321)),
      (Icons.storefront_rounded, 'Shop', Color(0xFFE2894A)),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _ValuePill(
              icon: items[i].$1,
              label: items[i].$2,
              color: items[i].$3,
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }
}

class _ValuePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _ValuePill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[200] : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
