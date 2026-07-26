import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/school_admin_provider.dart';
import 'admin_account_menu.dart';

/// Shared admin top bar: school identity + actions.
class AdminShellHeader extends StatelessWidget implements PreferredSizeWidget {
  final SchoolAdminProvider admin;
  final VoidCallback? onEditSchool;

  const AdminShellHeader({
    super.key,
    required this.admin,
    this.onEditSchool,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final schoolName = (admin.school?.name ?? '').trim().isNotEmpty
        ? admin.school!.name
        : 'School admin';
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schoolName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'School administration',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
      actions: [
        AdminAccountMenu(onEditSchool: onEditSchool),
      ],
    );
  }
}
