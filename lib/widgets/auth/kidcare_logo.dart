import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_branding.dart';
import '../../core/constants/auth_assets.dart';
import '../../core/theme/app_theme.dart';

class KidCareLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Color? color;
  final bool showTagline;
  final bool compact;

  const KidCareLogo({
    super.key,
    this.iconSize = 28,
    this.fontSize = 22,
    this.color,
    this.showTagline = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppTheme.primaryBlue;
    final accentColor = color ?? AppTheme.softGreen;
    final mutedColor = (color ?? AppTheme.textPrimary).withValues(alpha: 0.65);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(iconSize * 0.45),
                boxShadow: color == null
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: SvgPicture.asset(
                AuthAssets.logoMark,
                width: iconSize * 1.85,
                height: iconSize * 1.85,
              ),
            ),
            const SizedBox(width: 12),
            compact ? _CompactWordmark(color: color, fontSize: fontSize) : _StackedWordmark(
              primaryColor: primaryColor,
              accentColor: accentColor,
              fontSize: fontSize,
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            AppBranding.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize * 0.52,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: mutedColor,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ],
    );
  }
}

class _StackedWordmark extends StatelessWidget {
  final Color primaryColor;
  final Color accentColor;
  final double fontSize;

  const _StackedWordmark({
    required this.primaryColor,
    required this.accentColor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppBranding.nameLine1,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.05,
            color: primaryColor,
          ),
        ),
        Text(
          AppBranding.nameLine2,
          style: TextStyle(
            fontSize: fontSize * 0.88,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.1,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}

class _CompactWordmark extends StatelessWidget {
  final Color? color;
  final double fontSize;

  const _CompactWordmark({required this.color, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppBranding.name,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color ?? AppTheme.primaryBlue,
        letterSpacing: -0.3,
        height: 1.15,
      ),
    );
  }
}
