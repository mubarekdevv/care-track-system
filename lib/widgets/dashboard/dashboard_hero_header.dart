import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../navigation/dashboard_header_actions.dart';
import '../profile/user_profile_avatar.dart';

/// Gradient welcome card shared across role dashboard home tabs.
class DashboardHeroHeader extends StatelessWidget {
  final Gradient gradient;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final bool avatarOnRight;
  final bool showGradientRing;
  final UserModel? profileUser;
  final Widget? trailing;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const DashboardHeroHeader({
    super.key,
    required this.gradient,
    required this.accentColor,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.avatarOnRight = true,
    this.showGradientRing = false,
    this.profileUser,
    this.trailing,
    this.footer,
    this.padding = const EdgeInsets.all(22),
    this.margin = const EdgeInsets.fromLTRB(20, 16, 20, 12),
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = profileUser ?? auth.currentUser;
    final previewKey = auth.profilePhotoPreview != null ? 'preview' : (user?.profilePic ?? '');
    final avatar = UserProfileAvatar(
      key: ValueKey('hero-${user?.uid}-$previewKey'),
      user: user,
      radius: avatarOnRight ? 28 : 26,
      editable: false,
      showGradientRing: showGradientRing,
    );

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: avatarOnRight ? 14 : 12,
              fontWeight: avatarOnRight ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        if (subtitle != null) SizedBox(height: avatarOnRight ? 6 : 2),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: avatarOnRight ? 24 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    return Padding(
      padding: margin,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(avatarOnRight ? 22 : 24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeaderActions(),
            SizedBox(height: avatarOnRight ? 18 : 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: avatarOnRight
                  ? [
                      Expanded(child: titleColumn),
                      avatar,
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ]
                  : [
                      avatar,
                      const SizedBox(width: 14),
                      Expanded(child: titleColumn),
                      if (trailing != null) trailing!,
                    ],
            ),
            if (badgeText != null) ...[
              SizedBox(height: avatarOnRight ? 14 : 0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: 20),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
