import 'package:flutter/material.dart';

import 'app_branding.dart';
import 'auth_assets.dart';
import 'marketplace_assets.dart';

/// Curated welcome carousel — each slide uses a role- or feature-specific photo.
class WelcomeSlide {
  final String headline;
  final String caption;
  final String assetPath;
  final String? networkUrl;
  final Color accent;
  final IconData icon;

  const WelcomeSlide({
    required this.headline,
    required this.caption,
    required this.assetPath,
    this.networkUrl,
    required this.accent,
    required this.icon,
  });
}

class WelcomeSlides {
  WelcomeSlides._();

  static const List<WelcomeSlide> all = [
    WelcomeSlide(
      headline: 'Track • Manage • Connect',
      caption: 'Child & student tracking and management in one hub',
      assetPath: AuthAssets.welcomeHero,
      accent: Color(0xFF4A90E2),
      icon: Icons.favorite_rounded,
    ),
    WelcomeSlide(
      headline: 'Parents stay in the loop',
      caption: 'Progress, health updates, and billing — always at your fingertips',
      assetPath: AuthAssets.registerHero,
      accent: Color(0xFF4A90E2),
      icon: Icons.family_restroom_rounded,
    ),
    WelcomeSlide(
      headline: 'Teachers teach with clarity',
      caption: 'Attendance, grades, and parent messages in one calm workspace',
      assetPath: 'assets/images/auth/register_teacher.svg',
      accent: Color(0xFF7ED321),
      icon: Icons.school_rounded,
    ),
    WelcomeSlide(
      headline: 'Kids learn through play',
      caption: 'Quests, badges, and schedules made friendly for young explorers',
      assetPath: 'assets/images/auth/register_child.svg',
      accent: Color(0xFF9013FE),
      icon: Icons.stars_rounded,
    ),
    WelcomeSlide(
      headline: 'Healthcare you can trust',
      caption: 'Vaccinations, visits, and growth records — shared safely with clinics',
      assetPath: 'assets/images/auth/register_healthcare.svg',
      accent: Color(0xFFE2894A),
      icon: Icons.medical_services_rounded,
    ),
    WelcomeSlide(
      headline: '${AppBranding.shopName} essentials',
      caption: 'Books, uniforms, and supplies curated for school success',
      assetPath: MarketplaceAssets.promoBackToSchool,
      networkUrl: MarketplaceAssets.urlPromoBackToSchool,
      accent: Color(0xFF357ABD),
      icon: Icons.storefront_rounded,
    ),
  ];
}
