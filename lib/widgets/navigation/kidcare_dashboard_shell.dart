import 'package:flutter/material.dart';

import '../../core/layout/app_breakpoints.dart';
import '../../core/theme/theme_helpers.dart';
import 'dashboard_shell_scope.dart';
import 'kidcare_drawer.dart';
import 'kidcare_quick_panel.dart';

/// Shared outer scaffold for role dashboards — drawer, quick panel, tab stack,
/// and responsive primary navigation (bottom bar vs rail).
class KidCareDashboardShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final List<NavigationDestination> destinations;
  final List<Widget> children;

  const KidCareDashboardShell({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.destinations,
    required this.children,
  });

  @override
  State<KidCareDashboardShell> createState() => _KidCareDashboardShellState();
}

class _KidCareDashboardShellState extends State<KidCareDashboardShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final useRail = AppBreakpoints.isExpanded(context);
    final tabBody = IndexedStack(
      index: widget.selectedIndex,
      children: widget.children,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ThemeHelpers.pageBackground(context),
      drawer: KidCareDrawer(
        selectedNavIndex: widget.selectedIndex,
        onTabSelected: widget.onIndexChanged,
      ),
      endDrawer: const KidCareQuickPanel(),
      body: DashboardShellScope(
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        openEndDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
        child: useRail
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: widget.selectedIndex,
                    onDestinationSelected: widget.onIndexChanged,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in widget.destinations)
                        NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon ?? destination.icon,
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: tabBody),
                ],
              )
            : tabBody,
      ),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onIndexChanged,
              destinations: widget.destinations,
            ),
    );
  }
}
