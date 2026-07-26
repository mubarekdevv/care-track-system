import 'package:child_and_student_care_and_tracking_app/models/product_model.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/add_child_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/link_child_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/billing_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/child_timeline_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/parent_dashboard.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/cart_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/checkout_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/my_orders_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/order_detail_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/parent_messages_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/product_detail_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/shared/chat_screen.dart';
import 'package:child_and_student_care_and_tracking_app/screens/parent/reports_screen.dart';
import 'package:flutter/material.dart';
import '../../screens/auth/auth_wrapper.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/role_onboarding_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/registration_paths_screen.dart';
import '../../screens/auth/student_register_screen.dart';
import '../../screens/auth/link_parent_screen.dart';

class AppRoutes {
  // Route Names (Constants)
  static const String roleSelection = '/';
  static const String welcomeRoleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
  static const String registrationPaths = '/registration-paths';
  static const String studentRegister = '/student-register';
  static const String linkParent = '/link_parent';
  static const String parentHome = '/parent_home';
  static const String addChildScreen = '/add_child';
  static const String linkChild = '/link_child';
  static const String childTimeline = '/child_timeline';
  static const String billing = '/billing';
  static const String reports = '/reports';
  static const String productDetail = '/product_detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String myOrders = '/my_orders';
  static const String orderDetail = '/order_detail';
  static const String messages = '/messages';
  static const String chat = '/chat';

  // 🗺️ The Unified Map of Routes
  static Map<String, WidgetBuilder> get routes => {
        roleSelection: (context) => const AuthWrapper(),
        welcomeRoleSelection: (context) => const RoleSelectionScreen(),
        register: (context) => const RegisterScreen(),
        login: (context) => const LoginScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        onboarding: (context) => const RoleOnboardingScreen(),
        registrationPaths: (context) => const RegistrationPathsScreen(),
        studentRegister: (context) => const StudentRegisterScreen(),
        linkParent: (context) => const LinkParentScreen(),
        parentHome: (context) => const ParentDashboard(),
        addChildScreen: (context) => const AddChildScreen(),
        linkChild: (context) => const LinkChildScreen(),
        childTimeline: (context) => const ChildTimelineScreen(),
        billing: (context) => const BillingScreen(),
        reports: (context) => const ReportsScreen(),
        productDetail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! ProductModel) {
            return const Scaffold(
              body: Center(child: Text('Product not found')),
            );
          }
          return ProductDetailScreen(product: args);
        },
        cart: (context) => const CartScreen(),
        checkout: (context) => const CheckoutScreen(),
        myOrders: (context) => const MyOrdersScreen(),
        orderDetail: (context) => const OrderDetailScreen(),
        messages: (context) => const ParentMessagesScreen(),
        chat: (context) {
          return const ChatScreen();
        },
      };

  // Helper function for clean navigation
  static void push(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }
}
