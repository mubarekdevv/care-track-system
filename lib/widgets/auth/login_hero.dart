import 'package:flutter/material.dart';
import '../../core/constants/auth_assets.dart';
import '../../core/theme/app_theme.dart';
import 'auth_illustration.dart';
import 'kidcare_logo.dart';

class LoginHeroIllustration extends StatelessWidget {
  const LoginHeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthIllustration.hero(
      assetPath: AuthAssets.loginHero,
      height: 160,
      fallback: SizedBox(
        height: 160,
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 52),
          ),
        ),
      ),
    );
  }
}

class LoginHeader extends StatelessWidget {
  final VoidCallback onBack;

  const LoginHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
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
                  color: isDark ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
            const Spacer(),
            const KidCareLogo(iconSize: 20, fontSize: 16, compact: true),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: LoginHeroIllustration(),
        ),
      ],
    );
  }
}
