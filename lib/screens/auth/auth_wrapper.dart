import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/user_role.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../child/child_dashboard.dart';
import '../healthcare/healthcare_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
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

        if (authProvider.isAuthenticated) {
          final user = authProvider.currentUser;
          if (user != null) {
            final role = UserRole.fromLabel(user.role);

            if (role == UserRole.parent) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<ChildProvider>(context, listen: false)
                    .startListeningToChildren(user.uid);
              });
              return const ParentDashboard();
            }

            if (role == UserRole.teacher) {
              return const TeacherDashboard();
            }

            if (role == UserRole.child) {
              return const ChildDashboard();
            }

            if (role == UserRole.healthcare) {
              return const HealthcareDashboard();
            }

            return const _RolePlaceholderDashboard(
              title: 'Dashboard',
              message: 'This role dashboard is under construction.',
            );
          }
        }

        return const WelcomeScreen();
      },
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
