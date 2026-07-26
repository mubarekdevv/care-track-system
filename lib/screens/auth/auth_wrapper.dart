import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/healthcare_provider.dart';
import '../../providers/marketplace_orders_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/school_admin_provider.dart';
import '../../providers/teacher_overview_provider.dart';
import '../../providers/teacher_homework_provider.dart';
import '../../providers/teacher_attendance_provider.dart';
import '../admin/admin_dashboard.dart';
import '../admin/admin_setup_gate.dart';
import '../child/child_dashboard.dart';
import 'student_profile_setup_screen.dart';
import 'teacher_profile_setup_screen.dart';
import 'healthcare_profile_setup_screen.dart';
import '../healthcare/healthcare_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import 'force_password_change_screen.dart';
import 'welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          );
        }

        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          return const _AuthenticatedRouter();
        }

        return const WelcomeScreen();
      },
    );
  }
}

class _AuthenticatedRouter extends StatefulWidget {
  const _AuthenticatedRouter();

  @override
  State<_AuthenticatedRouter> createState() => _AuthenticatedRouterState();
}

class _AuthenticatedRouterState extends State<_AuthenticatedRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SchoolAdminProvider>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final schoolAdmin = context.watch<SchoolAdminProvider>();
    final user = auth.currentUser!;

    if (schoolAdmin.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (schoolAdmin.bootstrapNeeded && schoolAdmin.canClaimAdmin) {
      return const FirstAdminSetupScreen();
    }

    if (schoolAdmin.bootstrapNeeded) {
      return const SchoolNotReadyScreen();
    }

    if (auth.mustChangePassword) {
      return const ForcePasswordChangeScreen();
    }

    final role = UserRole.fromLabel(user.role);

    if (role == UserRole.child && !auth.isStudentProfileComplete) {
      return const StudentProfileSetupScreen();
    }

    if (auth.shouldShowTeacherProfileSetup) {
      return const TeacherProfileSetupScreen(isFirstLogin: true);
    }

    if (auth.shouldShowHealthcareProfileSetup) {
      return const HealthcareProfileSetupScreen(isFirstLogin: true);
    }

    if (role == UserRole.admin) {
      return const AdminDashboard();
    }

    if (role == UserRole.parent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ChildProvider>(context, listen: false)
            .startListeningToChildren(user.uid);
        Provider.of<MarketplaceOrdersProvider>(context, listen: false)
            .startListening(user.uid);
        Provider.of<MessagingProvider>(context, listen: false)
            .startListeningForParent(user.uid);
      });
      return const ParentDashboard();
    }

    if (role == UserRole.teacher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overview = Provider.of<TeacherOverviewProvider>(context, listen: false);
        Provider.of<MessagingProvider>(context, listen: false)
            .startListeningForTeacher(user.uid);
        overview.startListening(teacherId: user.uid, school: schoolAdmin);
        Provider.of<TeacherHomeworkProvider>(context, listen: false)
            .startListening(user.uid);
        Provider.of<TeacherAttendanceProvider>(context, listen: false)
            .bindToOverview(overview);
      });
      return const TeacherDashboard();
    }

    if (role == UserRole.child) {
      final linkedId = user.linkedStudentId;
      if (linkedId != null && linkedId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<ChildProvider>(context, listen: false)
              .startListeningToLinkedChild(linkedId);
          Provider.of<MessagingProvider>(context, listen: false)
              .startListeningForStudent(user.uid);
        });
      }
      return const ChildDashboard();
    }

    if (role == UserRole.healthcare) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<HealthcareProvider>(context, listen: false)
            .startListening(healthcareUserId: user.uid);
        Provider.of<MessagingProvider>(context, listen: false)
            .startListeningForHealthcare(user.uid);
      });
      return const HealthcareDashboard();
    }

    return const _RolePlaceholderDashboard(
      title: 'Dashboard',
      message: 'This role dashboard is under construction.',
    );
  }
}

class _RolePlaceholderDashboard extends StatelessWidget {
  final String title;
  final String message;

  const _RolePlaceholderDashboard({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkBackground
          : AppTheme.warmNeutral,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_rounded,
                  size: 56, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
