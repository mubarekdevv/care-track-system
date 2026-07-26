import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../constants/user_role.dart';

enum KidCareDrawerAction {
  tab,
  route,
  logout,
}

class KidCareDrawerItem {
  final String label;
  final IconData icon;
  final KidCareDrawerAction action;
  final int? tabIndex;
  final String? route;
  final bool isDividerAfter;

  const KidCareDrawerItem({
    required this.label,
    required this.icon,
    this.action = KidCareDrawerAction.tab,
    this.tabIndex,
    this.route,
    this.isDividerAfter = false,
  });

  const KidCareDrawerItem.divider()
      : label = '',
        icon = Icons.horizontal_rule_rounded,
        action = KidCareDrawerAction.tab,
        tabIndex = null,
        route = null,
        isDividerAfter = false;
}

class DrawerNavigation {
  DrawerNavigation._();

  static List<KidCareDrawerItem> itemsFor(UserRole? role) {
    switch (role) {
      case UserRole.parent:
        return const [
          KidCareDrawerItem(label: 'Home', icon: Icons.home_rounded, tabIndex: 0),
          KidCareDrawerItem(label: 'Marketplace', icon: Icons.storefront_rounded, tabIndex: 1),
          KidCareDrawerItem(label: 'Alerts', icon: Icons.notifications_rounded, tabIndex: 2),
          KidCareDrawerItem(label: 'Profile', icon: Icons.person_rounded, tabIndex: 3, isDividerAfter: true),
          KidCareDrawerItem(
            label: 'School Messages',
            icon: Icons.chat_rounded,
            action: KidCareDrawerAction.route,
            route: AppRoutes.messages,
          ),
          KidCareDrawerItem(
            label: 'My Orders',
            icon: Icons.local_shipping_rounded,
            action: KidCareDrawerAction.route,
            route: AppRoutes.myOrders,
          ),
          KidCareDrawerItem(
            label: 'Add Child',
            icon: Icons.child_care_rounded,
            action: KidCareDrawerAction.route,
            route: AppRoutes.addChildScreen,
          ),
          KidCareDrawerItem(
            label: 'Link with code',
            icon: Icons.link_rounded,
            action: KidCareDrawerAction.route,
            route: AppRoutes.linkChild,
          ),
          KidCareDrawerItem(
            label: 'Reports',
            icon: Icons.analytics_rounded,
            action: KidCareDrawerAction.route,
            route: AppRoutes.reports,
          ),
          KidCareDrawerItem(
            label: 'Billing',
            icon: Icons.receipt_long_rounded,
            action: KidCareDrawerAction.route,
            route: AppRoutes.billing,
            isDividerAfter: true,
          ),
        ];
      case UserRole.teacher:
        return const [
          KidCareDrawerItem(label: 'Overview', icon: Icons.dashboard_rounded, tabIndex: 0),
          KidCareDrawerItem(label: 'Attendance', icon: Icons.people_rounded, tabIndex: 1),
          KidCareDrawerItem(label: 'Homework', icon: Icons.assignment_rounded, tabIndex: 2),
          KidCareDrawerItem(label: 'Messages', icon: Icons.chat_rounded, tabIndex: 3),
          KidCareDrawerItem(label: 'Profile', icon: Icons.person_rounded, tabIndex: 4, isDividerAfter: true),
        ];
      case UserRole.child:
        return const [
          KidCareDrawerItem(label: 'Home', icon: Icons.stars_rounded, tabIndex: 0),
          KidCareDrawerItem(label: 'My Tasks', icon: Icons.assignment_rounded, tabIndex: 1),
          KidCareDrawerItem(label: 'Badges', icon: Icons.emoji_events_rounded, tabIndex: 2),
          KidCareDrawerItem(label: 'Profile', icon: Icons.person_rounded, tabIndex: 3, isDividerAfter: true),
          KidCareDrawerItem(
            label: 'My parent link code',
            icon: Icons.pin_rounded,
            action: KidCareDrawerAction.route,
            route: AppRoutes.linkParent,
          ),
        ];
      case UserRole.healthcare:
        return const [
          KidCareDrawerItem(label: 'Home Center', icon: Icons.healing_rounded, tabIndex: 0),
          KidCareDrawerItem(label: 'Directory', icon: Icons.folder_shared_rounded, tabIndex: 1),
          KidCareDrawerItem(label: 'Visits', icon: Icons.calendar_month_rounded, tabIndex: 2),
          KidCareDrawerItem(label: 'Credentials', icon: Icons.medical_services_rounded, tabIndex: 3, isDividerAfter: true),
        ];
      default:
        return const [
          KidCareDrawerItem(label: 'Home', icon: Icons.home_rounded, tabIndex: 0),
        ];
    }
  }
}
