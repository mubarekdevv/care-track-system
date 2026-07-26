import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Shared theme-aware colors for pages that need explicit backgrounds.
class ThemeHelpers {
  ThemeHelpers._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBackground(BuildContext context) =>
      isDark(context) ? AppTheme.darkBackground : AppTheme.warmNeutral;

  static Color cardBackground(BuildContext context) =>
      isDark(context) ? AppTheme.darkSurface : Colors.white;

  static Color primaryText(BuildContext context) =>
      isDark(context) ? Colors.white : AppTheme.textPrimary;

  static Color secondaryText(BuildContext context) =>
      isDark(context) ? Colors.grey[400]! : AppTheme.textSecondary;
}
