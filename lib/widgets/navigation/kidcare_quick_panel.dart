import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/role_styles.dart';
import '../../core/constants/user_role.dart';
import '../../core/constants/app_branding.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/healthcare_provider.dart';

/// Quick actions panel (slides from the right).
class KidCareQuickPanel extends StatelessWidget {
  const KidCareQuickPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final role = UserRole.fromLabel(user?.role);
    final accent = RoleStyles.forRole(user?.role ?? 'Parent')['accent'] as Color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: 300,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.bolt_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Quick Panel',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Shortcuts and live status for your ${user?.role ?? 'dashboard'}.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ..._quickCards(context, role, isDark, accent),
              const Spacer(),
              Center(
                child: Text(
                  '${AppBranding.name} v1.0 • Safe & Family-first',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _quickCards(
    BuildContext context,
    UserRole? role,
    bool isDark,
    Color accent,
  ) {
    switch (role) {
      case UserRole.parent:
        final childCount = Provider.of<ChildProvider>(context).children.length;
        return [
          _QuickCard(
            icon: Icons.family_restroom_rounded,
            title: '$childCount ${childCount == 1 ? 'Child' : 'Children'}',
            subtitle: 'On your care plan',
            accent: accent,
            isDark: isDark,
          ),
          _QuickCard(
            icon: Icons.notifications_active_rounded,
            title: 'Alerts',
            subtitle: 'Check billing & health reminders',
            accent: AppTheme.primaryBlue,
            isDark: isDark,
          ),
          _QuickCard(
            icon: Icons.storefront_rounded,
            title: 'Marketplace',
            subtitle: 'Books, uniforms & supplies',
            accent: AppTheme.softGreen,
            isDark: isDark,
          ),
        ];
      case UserRole.healthcare:
        final healthcare = Provider.of<HealthcareProvider>(context);
        return [
          _QuickCard(
            icon: Icons.groups_rounded,
            title: '${healthcare.activePatientCount} Patients',
            subtitle: 'Registered in ${AppBranding.name}',
            accent: accent,
            isDark: isDark,
          ),
          _QuickCard(
            icon: Icons.event_available_rounded,
            title: '${healthcare.todayAppointments.length} Visits Today',
            subtitle: 'Scheduled clinic appointments',
            accent: AppTheme.primaryBlue,
            isDark: isDark,
          ),
          _QuickCard(
            icon: Icons.vaccines_rounded,
            title: '${healthcare.totalVaccineRecords} Vaccines',
            subtitle: 'On record across patients',
            accent: AppTheme.softGreen,
            isDark: isDark,
          ),
        ];
      case UserRole.teacher:
        return [
          _QuickCard(
            icon: Icons.school_rounded,
            title: 'Grade 3-A',
            subtitle: 'Room 104 • North Academy',
            accent: accent,
            isDark: isDark,
          ),
          _QuickCard(
            icon: Icons.assignment_turned_in_rounded,
            title: 'Grading Queue',
            subtitle: 'Review homework submissions',
            accent: AppTheme.primaryBlue,
            isDark: isDark,
          ),
        ];
      case UserRole.child:
        return [
          _QuickCard(
            icon: Icons.stars_rounded,
            title: 'Keep Going!',
            subtitle: 'Complete tasks to earn XP & badges',
            accent: accent,
            isDark: isDark,
          ),
          _QuickCard(
            icon: Icons.schedule_rounded,
            title: 'Today\'s Schedule',
            subtitle: 'See classes and activities',
            accent: AppTheme.primaryBlue,
            isDark: isDark,
          ),
        ];
      default:
        return [
          _QuickCard(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            subtitle: 'Your ${AppBranding.name} hub',
            accent: accent,
            isDark: isDark,
          ),
        ];
    }
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
