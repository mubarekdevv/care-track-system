import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/child_model.dart';

/// Shows whether the student has connected their login to the school profile.
class ChildAccountLinkStatusChip extends StatelessWidget {
  final ChildModel child;
  final bool compact;

  const ChildAccountLinkStatusChip({
    super.key,
    required this.child,
    this.compact = false,
  });

  bool get _linked => child.isAccountLinked;

  @override
  Widget build(BuildContext context) {
    if (_linked) {
      return _chip(
        label: compact ? 'Login linked' : 'Student account connected',
        icon: Icons.link_rounded,
        color: AppTheme.softGreen,
      );
    }
    return _chip(
      label: compact ? 'Awaiting login' : 'Waiting for student to sign in & enter code',
      icon: Icons.hourglass_empty_rounded,
      color: Colors.orange,
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
