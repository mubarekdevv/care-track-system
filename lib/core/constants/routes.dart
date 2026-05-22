import 'package:child_and_student_care_and_tracking_app/screens/parent/add_child_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/parent_dashboard.dart';
import 'package:flutter/material.dart';
import '../../screens/auth/auth_wrapper.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/login_screen.dart'; // Ensure this exists

class AppRoutes {
  // Route Names (Constants)
  static const String roleSelection = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String parentHome = '/parent_home';
  static const String addChildScreen = '/add_child';

  // 🗺️ The Unified Map of Routes
  static Map<String, WidgetBuilder> get routes => {
        roleSelection: (context) => const AuthWrapper(),
        register: (context) => const RegisterScreen(),
        login: (context) => const LoginScreen(), // ✅ Correctly inside the map
        parentHome: (context) => const ParentDashboard(),
        addChildScreen: (context)=> const AddChildScreen()
      };

  // Helper function for clean navigation
  static void push(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }
}
