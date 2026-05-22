import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../parent/parent_dashboard.dart';
import 'role_selection_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // 🌀 Show smooth loading screen while checking session
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          );
        }

        // 🛡️ User is Authenticated, route based on role
        if (authProvider.isAuthenticated) {
          final user = authProvider.currentUser;
          if (user != null) {
            // Auto start child stream if user is a Parent
            if (user.role == 'Parent') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<ChildProvider>(context, listen: false)
                    .startListeningToChildren(user.uid);
              });
              return const ParentDashboard();
            } else if (user.role == 'Teacher') {
              return const Scaffold(
                body: Center(
                  child: Text(
                    "Welcome Teacher! Dashboard under construction.",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            } else if (user.role == 'Healthcare') {
              return const Scaffold(
                body: Center(
                  child: Text(
                    "Welcome Doctor! Dashboard under construction.",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            } else if (user.role == 'Child') {
              return const Scaffold(
                body: Center(
                  child: Text(
                    "Welcome Child! Dashboard under construction.",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            }
          }
        }

        // 🚪 No session found, show role selection onboarding
        return const RoleSelectionScreen();
      },
    );
  }
}
