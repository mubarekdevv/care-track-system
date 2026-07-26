import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/add_child_display_mode.dart';
import '../../core/constants/role_styles.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/child_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/marketplace_orders_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/parent_preferences_provider.dart';
import '../../widgets/profile/kidcare_avatar_image.dart';
import '../../widgets/parent/child_account_link_status_chip.dart';
import '../../widgets/parent/parent_child_link_code_action.dart';
import '../../widgets/navigation/kidcare_section_tab_bar.dart';
import '../parent/child_timeline_screen.dart';
import '../../providers/school_admin_provider.dart';
import '../../widgets/dashboard/dashboard_hero_header.dart';
import '../../widgets/dashboard/dashboard_section_header.dart';
import '../../widgets/dashboard/dashboard_stat_card.dart';
import '../../widgets/dashboard/dashboard_tab_scaffold.dart';
import '../../widgets/navigation/kidcare_dashboard_shell.dart';
import '../../core/academic/enrollment_display.dart';
import '../../core/health/health_concerns.dart';
import '../../widgets/parent/add_child_action_button.dart';
import '../../widgets/parent/add_child_display_setting.dart';
import '../../widgets/settings/appearance_setting.dart';
import '../../widgets/profile/user_profile_avatar.dart';
import 'marketplace_tab.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _navIndex = 0;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return KidCareDashboardShell(
      selectedIndex: _navIndex,
      onIndexChanged: (index) => setState(() => _navIndex = index),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Shop'),
        NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts'),
        NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile'),
      ],
      children: [
        _ParentHomeTab(greeting: _greeting(), user: user),
        const MarketplaceTab(),
        const _AlertsTab(),
        const _ProfileTab(),
      ],
    );
  }
}

class _ParentHomeTab extends StatelessWidget {
  final String greeting;
  final UserModel? user;

  const _ParentHomeTab({required this.greeting, this.user});

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    final parentPrefs = Provider.of<ParentPreferencesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasChildren = childProvider.children.isNotEmpty;
    final showInlineAdd = hasChildren && parentPrefs.addChildDisplayMode == AddChildDisplayMode.inline;
    final showFloatingAdd = hasChildren && parentPrefs.addChildDisplayMode == AddChildDisplayMode.floating;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      floatingActionButton: showFloatingAdd ? const AddChildFloatingButton() : null,
      body: SafeArea(
        child: childProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: DashboardHeroHeader(
                      profileUser: user,
                      gradient: RoleStyles.forRole('Parent')['gradient'] as LinearGradient,
                      accentColor: RoleStyles.forRole('Parent')['accent'] as Color,
                      subtitle: greeting,
                      title: user?.fullName ?? 'Parent',
                      badgeText:
                          '${childProvider.children.length} ${childProvider.children.length == 1 ? 'child' : 'children'} on your care plan',
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildQuickStats(context)),
                  SliverToBoxAdapter(child: _buildQuickActions(context)),
                  SliverToBoxAdapter(
                    child: DashboardSectionHeader(
                      title: 'My Children',
                      trailing: showInlineAdd ? const AddChildActionButton(compact: true) : null,
                    ),
                  ),
                  if (childProvider.children.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyChildrenState(context, isDark))
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              index == childProvider.children.length - 1
                                  ? 0
                                  : 12),
                          child: _ChildProfileCard(
                              child: childProvider.children[index],
                              isDark: isDark),
                        ),
                        childCount: childProvider.children.length,
                      ),
                    ),
                  SliverToBoxAdapter(
                      child: _buildInsightCards(context, isDark)),
                  SliverToBoxAdapter(child: SizedBox(height: showFloatingAdd ? 88 : 24)),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();
    final messageProvider = context.watch<MessagingProvider>();
    final orderProvider = context.watch<MarketplaceOrdersProvider>();
    final unreadMessages = messageProvider.threads.where((t) => t.unreadByParent).length;
    final healthEnabled = childProvider.children.where((c) => c.healthModuleEnabled).length;

    return SizedBox(
      height: 128,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          DashboardStatCard(
            icon: Icons.school_rounded,
            label: 'Children',
            value: '${childProvider.children.length}',
            subtitle: 'Profiles added',
            accent: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
          DashboardStatCard(
            icon: Icons.chat_rounded,
            label: 'Messages',
            value: '$unreadMessages',
            subtitle: 'Unread',
            accent: const Color(0xFF9013FE),
          ),
          const SizedBox(width: 12),
          DashboardStatCard(
            icon: Icons.favorite_rounded,
            label: 'Health',
            value: '$healthEnabled',
            subtitle: 'Clinic access on',
            accent: AppTheme.softGreen,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.billing),
            child: DashboardStatCard(
              icon: Icons.receipt_long_rounded,
              label: 'Billing',
              value: '${orderProvider.orders.length}',
              subtitle: 'Order records',
              accent: const Color(0xFFE2894A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('Marketplace', Icons.storefront_rounded, AppTheme.primaryBlue, null),
      ('Reports', Icons.bar_chart_rounded, AppTheme.softGreen, AppRoutes.reports),
      ('Billing', Icons.payments_rounded, const Color(0xFFE2894A), AppRoutes.billing),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: actions
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () {
                        final route = item.$4;
                        if (route != null) {
                          Navigator.pushNamed(context, route);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Open ${item.$1} from the Shop tab')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(item.$2, color: item.$3, size: 22),
                            const SizedBox(height: 6),
                            Text(
                              item.$1,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyChildrenState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded,
                size: 56, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          const Text('No children added yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Add a child profile to track academics, health records, and marketplace recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                height: 1.45),
          ),
          const SizedBox(height: 20),
          const AddChildActionButton(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.linkChild),
            icon: const Icon(Icons.link_rounded),
            label: const Text('Link child who registered first'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (Provider.of<ParentPreferencesProvider>(context).addChildDisplayMode == AddChildDisplayMode.hidden)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Tip: You can also add children anytime from the side menu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightCards(BuildContext context, bool isDark) {
    final childProvider = context.watch<ChildProvider>();
    final hasEnrolledChildren = childProvider.children
        .where((c) => c.gradeLevelId != null && c.classRoomId != null)
        .isNotEmpty;
    final healthEnabled = childProvider.children.where((c) => c.healthModuleEnabled).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          _InsightPanel(
            isDark: isDark,
            title: 'Academic Progress',
            subtitle: hasEnrolledChildren
                ? 'Children are enrolled in grade. Grades will appear once teachers publish assessments.'
                : 'No grade enrollment yet. Enroll a child to see teacher-assigned subjects.',
            icon: Icons.auto_graph_rounded,
            color: AppTheme.primaryBlue,
            onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
          ),
          const SizedBox(height: 12),
          _InsightPanel(
            isDark: isDark,
            title: 'Health & doctors',
            subtitle: healthEnabled > 0
                ? '$healthEnabled child(ren) with clinic access. Open a child Health tab to assign doctors and message them.'
                : 'Select health follow-up needs when enrolling. Assign school doctors from each child\'s Health tab.',
            icon: Icons.health_and_safety_rounded,
            color: AppTheme.softGreen,
          ),
          const SizedBox(height: 12),
          _InsightPanel(
            isDark: isDark,
            title: 'Billing & Payments',
            subtitle:
                'Billing module is not active yet. Order history remains available from the shop.',
            icon: Icons.payments_rounded,
            color: const Color(0xFFE2894A),
            actionLabel: 'Open billing screen',
            onTap: () => Navigator.pushNamed(context, AppRoutes.billing),
          ),
        ],
      ),
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  final ChildModel child;
  final bool isDark;

  const _ChildProfileCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<SchoolAdminProvider>();
    final ageGradeLine = EnrollmentDisplay.childAgeAndGradeLine(
      admin: admin,
      age: child.age,
      gradeLevelId: child.gradeLevelId,
      classRoomId: child.classRoomId,
    );

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.childTimeline,
          arguments: child,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                KidCareAvatarImage(
                  photoUrl: child.imageUrl,
                  name: child.name,
                  radius: 32,
                  accent: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        ageGradeLine,
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.grey[400] : AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      KidCareSectionQuickLinks(
                        onSelectTab: (tab) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.childTimeline,
                            arguments: ChildTimelineRouteArgs(
                              child: child,
                              initialTabIndex: tab,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      ChildAccountLinkStatusChip(child: child, compact: true),
                      const SizedBox(height: 6),
                      Text(
                        _healthStatusLine(child),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _healthStatusColor(child),
                        ),
                      ),
                    ],
                  ),
                ),
                ParentChildLinkCodeIconButton(
                  child: child,
                  iconColor: isDark ? Colors.grey[400] : AppTheme.primaryBlue,
                ),
                Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.grey[500] : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _healthStatusLine(ChildModel child) {
    if (child.usesPrivateDoctor) return 'Private doctor — outside school';
    if (child.assignedDoctorId != null && child.assignedDoctorId!.isNotEmpty) {
      return 'School doctor assigned';
    }
    if (child.healthConcernIds.isNotEmpty) {
      return 'Follow-up: ${HealthConcerns.labelsForIds(child.healthConcernIds)}';
    }
    return 'No health follow-up selected';
  }

  Color _healthStatusColor(ChildModel child) {
    if (child.assignedDoctorId != null && child.assignedDoctorId!.isNotEmpty) {
      return AppTheme.softGreen;
    }
    if (child.usesPrivateDoctor) return AppTheme.textSecondary;
    if (child.healthConcernIds.isNotEmpty) return Colors.orange;
    return AppTheme.textSecondary;
  }
}

class _InsightPanel extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _InsightPanel({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                        ),
                      ),
                      if (actionLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          actionLabel!,
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orders = context.watch<MarketplaceOrdersProvider>().orders;
    final messageThreads = context.watch<MessagingProvider>().threads;
    final userId = context.watch<AuthProvider>().currentUser?.uid ?? '';

    final messageAlerts = messageThreads.take(5).map((thread) {
      return (
        'Message from ${thread.otherPartyName(userId)}',
        thread.lastMessage,
        Icons.chat_bubble_rounded,
        AppTheme.primaryBlue,
        'thread:${thread.id}',
      );
    });

    final orderAlerts = orders.take(5).map((order) {
      return (
        'Order #${order.shortId} • ${order.statusLabel}',
        '${order.itemCount} items • \$${order.subtotal.toStringAsFixed(2)}',
        Icons.local_shipping_rounded,
        order.statusColor(context),
        order.id,
      );
    });

    final alerts = [...messageAlerts, ...orderAlerts];

    return DashboardTabScaffold(
      title: 'Notifications',
      trailingActions: [
        IconButton(
          tooltip: 'School Messages',
          onPressed: () => AppRoutes.push(context, AppRoutes.messages),
          icon: const Icon(Icons.chat_rounded, color: AppTheme.primaryBlue),
        ),
        IconButton(
          tooltip: 'My Orders',
          onPressed: () => AppRoutes.push(context, AppRoutes.myOrders),
          icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryBlue),
        ),
      ],
      body: alerts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'No notifications yet.\nNew messages and order updates will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            )
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
            ),
            leading: Icon(alert.$3, color: alert.$4),
            title: Text(alert.$1,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(alert.$2),
            onTap: alert.$5 != null
                ? () {
                    final target = alert.$5!;
                    if (target.startsWith('thread:')) {
                      final threadId = target.substring(7);
                      for (final thread in messageThreads) {
                        if (thread.id == threadId) {
                          AppRoutes.push(context, AppRoutes.chat, arguments: thread);
                          return;
                        }
                      }
                    } else {
                      AppRoutes.push(context, AppRoutes.orderDetail, arguments: target);
                    }
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return DashboardTabScaffold(
      title: 'Profile',
      body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: UserProfileAvatar(radius: 44, user: user)),
            const SizedBox(height: 8),
            Text(
              'Tap your photo to update',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(user?.fullName ?? 'Parent',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Center(child: Chip(label: Text(user?.role ?? 'Parent'))),
            const SizedBox(height: 24),
            const AddChildDisplaySetting(),
            const SizedBox(height: 16),
            const AppearanceSetting(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Provider.of<ChildProvider>(context, listen: false)
                      .stopListening();
                  Provider.of<MarketplaceOrdersProvider>(context, listen: false)
                      .stopListening();
                  Provider.of<MessagingProvider>(context, listen: false)
                      .stopListening();
                  await Provider.of<AuthProvider>(context, listen: false)
                      .logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
    );
  }
}
