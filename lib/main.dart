import 'package:child_and_student_care_and_tracking_app/core/constants/app_branding.dart';
import 'package:child_and_student_care_and_tracking_app/core/theme/app_theme.dart';
import 'package:child_and_student_care_and_tracking_app/firebase_options.dart';
import 'package:child_and_student_care_and_tracking_app/providers/app_theme_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/auth_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/cart_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/child_gamification_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/healthcare_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/messaging_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/marketplace_orders_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/parent_preferences_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/school_admin_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/teacher_overview_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/teacher_homework_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/teacher_attendance_provider.dart';
import 'package:child_and_student_care_and_tracking_app/providers/child_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/routes.dart';
import 'core/firebase/firestore_bootstrap.dart';
import 'core/navigation/auth_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await configureFirestore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChildProvider()),
        ChangeNotifierProvider(create: (_) => ChildGamificationProvider()),
        ChangeNotifierProvider(create: (_) => HealthcareProvider()),
        ChangeNotifierProvider(create: (_) => ParentPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceOrdersProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => SchoolAdminProvider()),
        ChangeNotifierProvider(create: (_) => TeacherOverviewProvider()),
        ChangeNotifierProvider(create: (_) => TeacherHomeworkProvider()),
        ChangeNotifierProvider(create: (_) => TeacherAttendanceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<AppThemeProvider>();

    return MaterialApp(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: AppRoutes.roleSelection,
      onGenerateRoute: AuthNavigation.routeFor,
    );
  }
}
