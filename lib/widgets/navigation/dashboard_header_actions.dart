import 'package:flutter/material.dart';

import '../../core/constants/app_branding.dart';
import '../../core/theme/app_theme.dart';
import 'dashboard_shell_scope.dart';

/// Menu + quick panel controls embedded in gradient hero headers.
class DashboardHeaderActions extends StatelessWidget {
  const DashboardHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const DashboardNavLeading(isDark: false, useGlassStyle: true),
        const Spacer(),
        Text(
          AppBranding.headerLabel.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        const DashboardNavTrailing(isDark: false, useGlassStyle: true),
      ],
    );
  }
}

/// Resolves drawer vs back vs home for toolbar leading slot.
class DashboardNavLeading extends StatelessWidget {
  final bool isDark;
  final bool useGlassStyle;

  const DashboardNavLeading({
    super.key,
    required this.isDark,
    this.useGlassStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final shell = DashboardShellScope.maybeOf(context);
    if (shell != null) {
      return _buildButton(
        icon: Icons.menu_rounded,
        tooltip: 'Menu',
        onPressed: shell.openDrawer,
      );
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      return _buildButton(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Back',
        onPressed: () => navigator.pop(),
      );
    }

    return const SizedBox(width: 40);
  }

  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    if (useGlassStyle) {
      return _GlassHeaderButton(
        icon: icon,
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }
    return _NeutralHeaderButton(
      icon: icon,
      tooltip: tooltip,
      isDark: isDark,
      onPressed: onPressed,
    );
  }
}

/// Resolves quick panel vs home-to-dashboard for toolbar trailing slot.
class DashboardNavTrailing extends StatelessWidget {
  final bool isDark;
  final bool useGlassStyle;
  final List<Widget>? extraActions;

  const DashboardNavTrailing({
    super.key,
    required this.isDark,
    this.useGlassStyle = false,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    final shell = DashboardShellScope.maybeOf(context);
    final children = <Widget>[
      if (extraActions != null) ...extraActions!,
      if (shell != null)
        _buildButton(
          icon: Icons.auto_awesome_motion_rounded,
          tooltip: 'Quick panel',
          onPressed: shell.openEndDrawer,
        )
      else if (Navigator.of(context).canPop())
        _buildButton(
          icon: Icons.home_rounded,
          tooltip: 'Back to dashboard',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
    ];

    if (children.isEmpty) return const SizedBox(width: 40);
    if (children.length == 1) return children.first;
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    if (useGlassStyle) {
      return _GlassHeaderButton(
        icon: icon,
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }
    return _NeutralHeaderButton(
      icon: icon,
      tooltip: tooltip,
      isDark: isDark,
      onPressed: onPressed,
    );
  }
}

/// Slim toolbar for neutral pages (shop, lists, profile tabs).
class DashboardCompactToolbar extends StatelessWidget {
  final String? title;
  final List<Widget>? trailingActions;

  const DashboardCompactToolbar({
    super.key,
    this.title,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          DashboardNavLeading(isDark: isDark),
          if (title != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          ] else
            const Spacer(),
          DashboardNavTrailing(
            isDark: isDark,
            extraActions: trailingActions,
          ),
        ],
      ),
    );
  }
}

/// AppBar leading slot for nested scaffolds.
class DashboardToolbarLeading extends StatelessWidget {
  const DashboardToolbarLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: DashboardNavLeading(isDark: isDark),
    );
  }
}

/// AppBar actions slot for nested scaffolds.
class DashboardToolbarTrailing extends StatelessWidget {
  const DashboardToolbarTrailing({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DashboardNavTrailing(isDark: isDark),
    );
  }
}

class _GlassHeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _GlassHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _NeutralHeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onPressed;

  const _NeutralHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder,
              ),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
        ),
      ),
    );
  }
}
