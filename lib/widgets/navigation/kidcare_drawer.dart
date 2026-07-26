import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/role_styles.dart';
import '../../core/constants/user_role.dart';
import '../../core/navigation/drawer_navigation.dart';
import '../../core/navigation/kidcare_logout.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/kidcare_logo.dart';
import '../../widgets/profile/user_profile_avatar.dart';

/// Primary navigation drawer (slides from the left).
class KidCareDrawer extends StatelessWidget {
  final int selectedNavIndex;
  final ValueChanged<int>? onTabSelected;

  const KidCareDrawer({
    super.key,
    required this.selectedNavIndex,
    this.onTabSelected,
  });

  void _handleItemTap(BuildContext context, KidCareDrawerItem item) {
    Navigator.pop(context);

    switch (item.action) {
      case KidCareDrawerAction.tab:
        if (item.tabIndex != null) onTabSelected?.call(item.tabIndex!);
        break;
      case KidCareDrawerAction.route:
        if (item.route != null) {
          final navigator = Navigator.of(context);
          var found = false;
          navigator.popUntil((route) {
            if (route.settings.name == item.route) {
              found = true;
              return true;
            }
            return route.isFirst;
          });
          if (!found) navigator.pushNamed(item.route!);
        }
        break;
      case KidCareDrawerAction.logout:
        kidCareLogout(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final role = UserRole.fromLabel(user?.role);
    final roleStyle = RoleStyles.forRole(user?.role ?? 'Parent');
    final gradient = roleStyle['gradient'] as LinearGradient;
    final accent = roleStyle['accent'] as Color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = DrawerNavigation.itemsFor(role);

    return Drawer(
      width: 300,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      KidCareLogo(iconSize: 20, fontSize: 14, color: Colors.white, compact: true),
                      Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      UserProfileAvatar(
                        user: user,
                        radius: 28,
                        editable: false,
                        showGradientRing: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'KidCare User',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      user?.role ?? 'Parent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  for (final item in items) ...[
                    _DrawerTile(
                      item: item,
                      selected: item.tabIndex == selectedNavIndex,
                      accent: accent,
                      isDark: isDark,
                      onTap: () => _handleItemTap(context, item),
                    ),
                    if (item.isDividerAfter)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Divider(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: OutlinedButton.icon(
                onPressed: () => kidCareLogout(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final KidCareDrawerItem item;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.item,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? accent.withValues(alpha: isDark ? 0.18 : 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.18)
                        : (isDark ? Colors.white10 : AppTheme.warmNeutral),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: selected ? accent : (isDark ? Colors.grey[300] : AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: selected
                          ? accent
                          : (isDark ? Colors.white : AppTheme.textPrimary),
                    ),
                  ),
                ),
                if (selected) Icon(Icons.chevron_right_rounded, color: accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
