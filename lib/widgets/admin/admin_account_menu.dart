import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/kidcare_logout.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// App-bar account menu: school settings + sign out.
class AdminAccountMenu extends StatelessWidget {
  final VoidCallback? onEditSchool;

  const AdminAccountMenu({super.key, this.onEditSchool});

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.logout_rounded, color: AppTheme.primaryBlue.withValues(alpha: 0.85)),
        title: const Text('Sign out?'),
        content: const Text(
          'You will leave the admin console and return to role selection. '
          'Your school data stays saved in the cloud.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
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
    final user = context.watch<AuthProvider>().currentUser;
    final initial = (user?.fullName.isNotEmpty == true)
        ? user!.fullName[0].toUpperCase()
        : 'A';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'school' && onEditSchool != null) onEditSchool!();
        if (value == 'signout') _signOut(context);
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.fullName ?? 'Administrator',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (user?.email.isNotEmpty == true)
                Text(
                  user!.email,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (onEditSchool != null)
          const PopupMenuItem(
            value: 'school',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.school_outlined, size: 22),
              title: Text('School name'),
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: 'signout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded, size: 22, color: Colors.redAccent),
            title: Text('Sign out', style: TextStyle(color: Colors.redAccent)),
            dense: true,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
