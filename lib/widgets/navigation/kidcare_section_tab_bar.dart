import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// High-contrast section tabs (Timeline / Academics / Health) for child detail screens.
class KidCareSectionTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final bool isDark;

  const KidCareSectionTabBar({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      child: TabBar(
        controller: controller,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: isDark ? Colors.grey[400] : AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryBlue,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(
            height: 48,
            icon: Icon(Icons.timeline_rounded, size: 18),
            text: 'Timeline',
          ),
          Tab(
            height: 48,
            icon: Icon(Icons.school_rounded, size: 18),
            text: 'Academics',
          ),
          Tab(
            height: 48,
            icon: Icon(Icons.health_and_safety_rounded, size: 18),
            text: 'Health',
          ),
        ],
      ),
    );
  }
}

/// Compact chips to jump straight to Timeline / Academics / Health from lists.
class KidCareSectionQuickLinks extends StatelessWidget {
  final void Function(int tabIndex) onSelectTab;

  const KidCareSectionQuickLinks({super.key, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _Chip(
          label: 'Timeline',
          icon: Icons.timeline_rounded,
          color: AppTheme.primaryBlue,
          isDark: isDark,
          onTap: () => onSelectTab(0),
        ),
        _Chip(
          label: 'Academics',
          icon: Icons.school_rounded,
          color: AppTheme.softGreen,
          isDark: isDark,
          onTap: () => onSelectTab(1),
        ),
        _Chip(
          label: 'Health',
          icon: Icons.health_and_safety_rounded,
          color: const Color(0xFFE2894A),
          isDark: isDark,
          onTap: () => onSelectTab(2),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppTheme.textPrimary,
        ),
      ),
      backgroundColor: color.withValues(alpha: isDark ? 0.18 : 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      onPressed: onTap,
    );
  }
}
