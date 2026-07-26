import 'package:flutter/material.dart';
import '../../core/constants/auth_assets.dart';
import '../../core/constants/role_styles.dart';
import 'auth_illustration.dart';
import 'kidcare_logo.dart';

class RegisterHeroIllustration extends StatelessWidget {
  final String role;

  const RegisterHeroIllustration({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final roleStyle = RoleStyles.forRole(role);
    final accent = roleStyle['accent'] as Color;
    final icon = roleStyle['icon'] as IconData;

    return AuthIllustration.hero(
      assetPath: AuthAssets.registerHeroForRole(role),
      height: 160,
      fallback: _IconHeroFallback(accent: accent, icon: icon),
    );
  }
}

class _IconHeroFallback extends StatelessWidget {
  final Color accent;
  final IconData icon;

  const _IconHeroFallback({required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 56),
          ),
        ],
      ),
    );
  }
}

class RegisterRoleBadge extends StatelessWidget {
  final String role;

  const RegisterRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final roleStyle = RoleStyles.forRole(role);
    final gradient = roleStyle['gradient'] as LinearGradient;
    final icon = roleStyle['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (roleStyle['accent'] as Color).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Registering as $role',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterHeader extends StatelessWidget {
  final String role;
  final VoidCallback onBack;

  const RegisterHeader({
    super.key,
    required this.role,
    required this.onBack,
  });

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RegisterHeroIllustration(role: role),
        ),
      ],
    );
  }
}
