import 'package:flutter/material.dart';

/// Exposes outer dashboard [Scaffold] drawer actions to nested tab scaffolds.
class DashboardShellScope extends InheritedWidget {
  final VoidCallback openDrawer;
  final VoidCallback openEndDrawer;

  const DashboardShellScope({
    super.key,
    required this.openDrawer,
    required this.openEndDrawer,
    required super.child,
  });

  static DashboardShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DashboardShellScope>();
  }

  static DashboardShellScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'DashboardShellScope not found above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(DashboardShellScope oldWidget) => false;
}
