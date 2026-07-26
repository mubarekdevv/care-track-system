import 'package:flutter/material.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../core/constants/app_branding.dart';
import '../../core/constants/role_options.dart';
import '../../core/constants/role_styles.dart';
import '../../core/navigation/auth_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth/kidcare_logo.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = AppBreakpoints.isMediumOrWider(context);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: isDark ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const KidCareLogo(iconSize: 22, fontSize: 18, compact: true),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: Text(
                  'Choose Your Role',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Text(
                  'Select a profile type to log in or register for your ${AppBranding.name} dashboard.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: isWide
                        ? GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 1.6,
                            ),
                            itemCount: RoleOptions.all.length,
                            itemBuilder: (context, index) {
                              return _PremiumRoleCard(
                                option: RoleOptions.all[index],
                                onTap: () => AuthNavigation.openOnboarding(
                                  context,
                                  RoleOptions.all[index].role,
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: RoleOptions.all.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PremiumRoleCard(
                                  option: RoleOptions.all[index],
                                  onTap: () => AuthNavigation.openOnboarding(
                                    context,
                                    RoleOptions.all[index].role,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Center(
                  child: TextButton(
                    onPressed: () => AuthNavigation.openLogin(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumRoleCard extends StatefulWidget {
  final RoleOption option;
  final VoidCallback onTap;

  const _PremiumRoleCard({
    required this.option,
    required this.onTap,
  });

  @override
  State<_PremiumRoleCard> createState() => _PremiumRoleCardState();
}

class _PremiumRoleCardState extends State<_PremiumRoleCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  List<String> get _roleFeatures => switch (widget.option.role.label) {
        'Parent' => [
            'Track growth milestones',
            'Log immunization charts',
            'Shop supplies & materials',
          ],
        'Teacher' => [
            'Class attendance tracker',
            'Assign & score homework',
            'Direct parent chat logs',
          ],
        'Child' => [
            'Fun interactive schedule',
            'Badge rewards checklist',
            'View class assignments',
          ],
        'Healthcare' => [
            'Growth chart calculations',
            'Vaccination clinic logbook',
            'Track pediatric history',
          ],
        _ => [],
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = RoleStyles.forRole(widget.option.title);
    final accentColor = style['accent'] as Color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.96
              : _isHovered
                  ? 1.03
                  : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isDark
                  ? (_isHovered
                      ? accentColor.withValues(alpha: 0.08)
                      : AppTheme.darkSurface)
                  : (_isHovered
                      ? accentColor.withValues(alpha: 0.05)
                      : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? accentColor.withValues(alpha: 0.7)
                    : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
                width: _isHovered ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? accentColor.withValues(alpha: isDark ? 0.25 : 0.15)
                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: _isHovered ? 20 : 12,
                  offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: style['gradient'] as LinearGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          style['icon'] as IconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.option.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.option.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: _isHovered ? accentColor : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 14),
                  ..._roleFeatures.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: accentColor.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

