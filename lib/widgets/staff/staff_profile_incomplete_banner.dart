import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Reminds teachers / healthcare staff to finish profile setup from the dashboard.
class StaffProfileIncompleteBanner extends StatelessWidget {
  const StaffProfileIncompleteBanner({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.accentColor = AppTheme.primaryBlue,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Material(
        color: accentColor.withOpacity(isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: accentColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
