import 'package:flutter/material.dart';

/// Shared slide + fade transition for auth flow screens.
class AuthPageRoute<T> extends PageRouteBuilder<T> {
  AuthPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0.02),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Routes that use [AuthPageRoute] for smoother auth navigation.
class AuthRoutes {
  AuthRoutes._();

  static const authPaths = {
    '/login',
    '/register',
    '/forgot-password',
    '/role-selection',
    '/onboarding',
  };

  static bool isAuthPath(String? name) => authPaths.contains(name);
}
