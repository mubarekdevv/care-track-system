import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/auth_assets.dart';
import '../../core/theme/app_theme.dart';

/// Displays auth imagery: local JPEG → network URL → bundled SVG → fallback.
class AuthIllustration extends StatelessWidget {
  final String assetPath;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final bool showShadow;
  final Widget? fallback;

  const AuthIllustration({
    super.key,
    required this.assetPath,
    this.height = 160,
    this.width,
    this.fit = BoxFit.contain,
    this.borderRadius = BorderRadius.zero,
    this.showShadow = false,
    this.fallback,
  });

  /// Full-width hero banner on welcome / login / register screens.
  factory AuthIllustration.hero({
    required String assetPath,
    double height = 180,
    Widget? fallback,
  }) {
    return AuthIllustration(
      assetPath: assetPath,
      height: height,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(20),
      showShadow: true,
      fallback: fallback,
    );
  }

  /// Small square thumbnail for role tiles and feature cards.
  factory AuthIllustration.thumbnail({
    required String assetPath,
    double size = 52,
    Widget? fallback,
  }) {
    return AuthIllustration(
      assetPath: assetPath,
      height: size,
      width: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
      fallback: fallback,
    );
  }

  String get _jpegPath => AuthAssets.jpegPath(assetPath);

  String? get _networkUrl => AuthAssets.networkUrlFor(assetPath);

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      height: height,
      width: width ?? (fit == BoxFit.cover ? double.infinity : null),
      child: Image.asset(
        _jpegPath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildNetworkOrSvg(),
      ),
    );

    return _frame(image);
  }

  Widget _frame(Widget child) {
    Widget content = ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    if (showShadow) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildNetworkOrSvg() {
    final url = _networkUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loadingPlaceholder();
        },
        errorBuilder: (_, __, ___) => _buildSvg(),
      );
    }
    return _buildSvg();
  }

  Widget _buildSvg() {
    return SvgPicture.asset(
      assetPath,
      fit: fit,
      width: width,
      height: height,
      placeholderBuilder: (_) => _loadingPlaceholder(),
    );
  }

  Widget _loadingPlaceholder() {
    return fallback ??
        Container(
          color: AppTheme.primaryBlue.withValues(alpha: 0.06),
          alignment: Alignment.center,
          child: Icon(
            Icons.image_outlined,
            size: (height * 0.28).clamp(20, 48),
            color: AppTheme.textSecondary.withValues(alpha: 0.45),
          ),
        );
  }
}
