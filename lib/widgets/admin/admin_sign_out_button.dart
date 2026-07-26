import 'package:flutter/material.dart';

import '../../core/navigation/kidcare_logout.dart';
import '../../core/theme/app_theme.dart';

/// Confirmed sign-out for admin (and other roles).
class AdminSignOutButton extends StatelessWidget {
  final bool compact;

  const AdminSignOutButton({super.key, this.compact = false});

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will return to the role selection screen. '
          'Unsaved changes on this page are already saved to the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await kidCareLogout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        icon: const Icon(Icons.logout_rounded),
        tooltip: 'Sign out',
        onPressed: () => _confirm(context),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _confirm(context),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Sign out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textSecondary,
        side: const BorderSide(color: AppTheme.inputBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
