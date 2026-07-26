import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/healthcare_provider.dart';
import '../../providers/marketplace_orders_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../providers/teacher_overview_provider.dart';
import '../../providers/teacher_homework_provider.dart';
import '../../providers/teacher_attendance_provider.dart';
import '../../providers/child_gamification_provider.dart';

/// Stops role listeners, signs out of Firebase, returns to role selection.
Future<void> kidCareLogout(BuildContext context) async {
  void tryProvider<T>(void Function(T provider) action) {
    try {
      action(Provider.of<T>(context, listen: false));
    } catch (e, st) {
      debugPrint('kidCareLogout: skipped $T cleanup: $e');
      if (kDebugMode) debugPrint('$st');
    }
  }

  tryProvider<ChildProvider>((p) {
    p.stopListening();
    p.stopListeningToLinkedChild();
  });
  tryProvider<ChildGamificationProvider>((p) => p.unbindHomework());
  tryProvider<HealthcareProvider>((p) => p.stopListening());
  tryProvider<MarketplaceOrdersProvider>((p) => p.stopListening());
  tryProvider<MessagingProvider>((p) => p.stopListening());
  tryProvider<TeacherOverviewProvider>((p) => p.stopListening());
  tryProvider<TeacherHomeworkProvider>((p) => p.stopListening());
  tryProvider<TeacherAttendanceProvider>((p) => p.stopListening());
  tryProvider<SchoolAdminProvider>((p) => p.stopListening());

  try {
    await Provider.of<AuthProvider>(context, listen: false).logout();
  } catch (e, st) {
    debugPrint('kidCareLogout: auth logout failed: $e');
    if (kDebugMode) debugPrint('$st');
  }

  if (!context.mounted) return;

  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
    AppRoutes.welcomeRoleSelection,
    (_) => false,
  );
}
