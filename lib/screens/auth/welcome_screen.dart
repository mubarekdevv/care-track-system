import 'package:flutter/material.dart';
import '../../core/constants/app_branding.dart';
import '../../core/constants/role_options.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../core/navigation/auth_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/kidcare_logo.dart';
import '../../widgets/auth/role_option_tile.dart';
import '../../widgets/auth/welcome_hero_carousel.dart';
import '../../widgets/auth/welcome_value_strip.dart';

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
      duration: const Duration(milliseconds: 750),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
    final isWide = AppBreakpoints.isMediumOrWider(context);

    return Scaffold(
      body: Stack(
        children: [
          _WelcomeBackground(isDark: isDark),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 20,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: isWide
                          ? _WideLayout(isDark: isDark)
                          : _NarrowLayout(isDark: isDark),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  final bool isDark;

  const _WelcomeBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A2744), AppTheme.darkBackground]
              : [AppTheme.authGradientTop, AppTheme.warmNeutral],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(
              size: 220,
              color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.12),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: _GlowOrb(
              size: 180,
              color: AppTheme.softGreen.withValues(alpha: isDark ? 0.1 : 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final bool isDark;

  const _NarrowLayout({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: KidCareLogo(showTagline: true)),
        const SizedBox(height: 16),
        WelcomeHeroCarousel(isDark: isDark, height: 210),
        const SizedBox(height: 20),
        _WelcomeMainCard(isDark: isDark),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final bool isDark;

  const _WideLayout({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: KidCareLogo(showTagline: true)),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WelcomeHeroCarousel(isDark: isDark, height: 300),
            ),
            const SizedBox(width: 28),
            Expanded(child: _WelcomeMainCard(isDark: isDark)),
          ],
        ),
      ],
    );
  }
}

class _WelcomeMainCard extends StatelessWidget {
  final bool isDark;

  const _WelcomeMainCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppBranding.welcomeHeadline(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track children and students across school, health, and home—'
            'one management hub for parents, teachers, clinics, and families.',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
              height: 1.55,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          WelcomeValueStrip(isDark: isDark),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: 'Get Started',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => AuthNavigation.openRoleSelection(context),
          ),
          const SizedBox(height: 22),
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
                onTap: () => AuthNavigation.openOnboarding(context, option.role),
              ),
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }
}
