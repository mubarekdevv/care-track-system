import 'package:flutter/material.dart';
import '../../core/constants/auth_assets.dart';
import '../../core/constants/role_options.dart';
import '../../core/navigation/auth_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth/auth_illustration.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/kidcare_logo.dart';
import '../../widgets/auth/role_option_tile.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A2744), AppTheme.darkBackground]
                : [AppTheme.authGradientTop, AppTheme.warmNeutral],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: KidCareLogo()),
                    const SizedBox(height: 14),
                    AuthIllustration.hero(
                      assetPath: AuthAssets.welcomeHero,
                      height: 200,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to KidCare',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your complete child management and educational marketplace platform.',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AuthPrimaryButton(
                            label: 'Get Started',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => AuthNavigation.openRoleSelection(context),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Or continue as',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...RoleOptions.all.map(
                            (option) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: RoleOptionTile(
                                option: option,
                                onTap: () =>
                                    AuthNavigation.openOnboarding(context, option.role),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => AuthNavigation.openLogin(context),
                              child: const Text(
                                'Already have an account? Sign In',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Trusted by thousands of families and educators',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TrustBadges(isDark: isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  final bool isDark;

  const _TrustBadges({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const badges = [
      'Secure & Private',
      'HIPAA Compliant',
      'Mobile Friendly',
      'Award Winning',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: badges
          .map(
            (label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
