import 'package:flutter/material.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';

/// Clear, tappable "Add child" control for section headers and lists.
class AddChildActionButton extends StatelessWidget {
  final bool compact;

  const AddChildActionButton({super.key, this.compact = false});

  void _openAddChild(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.addChildScreen);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return TextButton.icon(
        onPressed: () => _openAddChild(context),
        icon: const Icon(Icons.child_care_outlined, size: 18),
        label: const Text('Add child'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _openAddChild(context),
      icon: const Icon(Icons.child_care_outlined, size: 18),
      label: const Text('Add child'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryBlue,
        side: const BorderSide(color: AppTheme.primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

/// Floating home-screen button — only shown when user opts in via settings.
class AddChildFloatingButton extends StatelessWidget {
  const AddChildFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FloatingActionButton.extended(
        heroTag: 'add_child_fab',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addChildScreen),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.child_care_rounded),
        label: const Text(
          'Add child',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
