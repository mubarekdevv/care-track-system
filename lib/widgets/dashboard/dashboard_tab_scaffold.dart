import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../navigation/dashboard_header_actions.dart';

/// Neutral tab page chrome — menu, optional title, quick panel, and body.
class DashboardTabScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? trailingActions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const DashboardTabScaffold({
    super.key,
    this.title,
    required this.body,
    this.trailingActions,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor ?? (isDark ? AppTheme.darkBackground : AppTheme.warmNeutral),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardCompactToolbar(
              title: title,
              trailingActions: trailingActions,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
