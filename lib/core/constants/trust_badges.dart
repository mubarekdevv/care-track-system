import 'package:flutter/material.dart';

import 'app_branding.dart';

/// Trust & safety copy shown on the welcome screen.
class TrustBadgeInfo {
  final String label;
  final IconData icon;
  final Color accent;
  final String summary;
  final String detail;

  const TrustBadgeInfo({
    required this.label,
    required this.icon,
    required this.accent,
    required this.summary,
    required this.detail,
  });
}

class TrustBadges {
  TrustBadges._();

  static const List<TrustBadgeInfo> all = [
    TrustBadgeInfo(
      label: 'Secure & Private',
      icon: Icons.lock_rounded,
      accent: Color(0xFF4A90E2),
      summary: 'Your family data stays protected.',
      detail:
          '${AppBranding.name} uses secure sign-in, encrypted connections, and private accounts '
          'so only the right people—parents, teachers, and care providers you trust—'
          'can see a child\'s information.',
    ),
    TrustBadgeInfo(
      label: 'HIPAA-aware',
      icon: Icons.health_and_safety_rounded,
      accent: Color(0xFF7ED321),
      summary: 'Built for sensitive health information.',
      detail:
          'HIPAA is a U.S. law that sets strict rules for protecting patient health '
          'records. ${AppBranding.name} is designed with healthcare privacy in mind: vaccination '
          'records, visit notes, and growth data are shared only with authorized roles.',
    ),
    TrustBadgeInfo(
      label: 'Mobile Friendly',
      icon: Icons.phone_iphone_rounded,
      accent: Color(0xFF9013FE),
      summary: 'Works beautifully on any screen size.',
      detail:
          'Whether you\'re on a phone, tablet, or desktop, ${AppBranding.name} adapts its layout '
          'so menus, dashboards, and the shop stay easy to read and tap.',
    ),
    TrustBadgeInfo(
      label: 'Award Winning',
      icon: Icons.emoji_events_rounded,
      accent: Color(0xFFE2894A),
      summary: 'Trusted by families and educators.',
      detail:
          '${AppBranding.name} brings child care, school updates, health tracking, and shopping '
          'into one friendly experience—recognized by families and schools for clarity '
          'and ease of use.',
    ),
  ];
}
