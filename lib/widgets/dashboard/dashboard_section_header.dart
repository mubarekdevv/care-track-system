import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Widget? trailing;

  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    Widget? actionWidget = trailing;

    if (actionWidget == null && actionLabel != null && onAction != null) {
      actionWidget = TextButton.icon(
        onPressed: onAction,
        icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
        label: Text(actionLabel!),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
            ),
          ),
          if (actionWidget != null) actionWidget,
        ],
      ),
    );
  }
}
