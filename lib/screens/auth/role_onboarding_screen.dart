import 'package:flutter/material.dart';
import '../../core/constants/role_onboarding.dart';
import '../../core/constants/role_styles.dart';
import '../../core/constants/user_role.dart';
import '../../core/constants/routes.dart';
import '../../core/navigation/auth_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth/auth_illustration.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/kidcare_logo.dart';

class RoleOnboardingScreen extends StatefulWidget {
  const RoleOnboardingScreen({super.key});

  @override
  State<RoleOnboardingScreen> createState() => _RoleOnboardingScreenState();
}

class _RoleOnboardingScreenState extends State<RoleOnboardingScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  UserRole get _role {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) return UserRole.fromLabel(args) ?? UserRole.parent;
    if (args is UserRole) return args;
    return UserRole.parent;
  }

  List<OnboardingSlide> get _slides => RoleOnboarding.slidesFor(_role);

  Map<String, dynamic> get _style => RoleStyles.forRole(_role.label);

  Color get _accent => _style['accent'] as Color;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_pageIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      switch (_role) {
        case UserRole.child:
          Navigator.pushNamed(context, AppRoutes.studentRegister);
          break;
        default:
          AuthNavigation.openRegister(context, _role);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _pageIndex == _slides.length - 1;

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color:
                              isDark ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const KidCareLogo(iconSize: 20, fontSize: 16, compact: true),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          AuthNavigation.openRegister(context, _role),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _OnboardingPage(
                      slide: slide,
                      role: _role,
                      accent: _accent,
                      isDark: isDark,
                      showWelcome: index == 0,
                    );
                  },
                ),
              ),
              _PageDots(
                  count: _slides.length, index: _pageIndex, accent: _accent),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: AuthPrimaryButton(
                  label: isLast ? 'Create Account' : 'Continue',
                  backgroundColor: _accent,
                  icon: isLast
                      ? Icons.person_add_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: () => AuthNavigation.openLogin(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color:
                            isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingSlide slide;
  final UserRole role;
  final Color accent;
  final bool isDark;
  final bool showWelcome;

  const _OnboardingPage({
    required this.slide,
    required this.role,
    required this.accent,
    required this.isDark,
    required this.showWelcome,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          if (showWelcome) ...[
            Text(
              RoleOnboarding.welcomeTitleFor(role),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              RoleOnboarding.welcomeSubtitleFor(role),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
          ],
          AuthIllustration.hero(
            assetPath: showWelcome
                ? RoleOnboarding.heroAssetFor(role)
                : slide.imageAsset,
            height: showWelcome ? 200 : 180,
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slide.icon, color: accent, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  final Color accent;

  const _PageDots({
    required this.count,
    required this.index,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? accent : accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
