import 'image_sources.dart';

/// Auth screen illustration and feature image paths.
/// Bundled JPEG (same base name as SVG) is preferred at runtime; SVG is fallback.
class AuthAssets {
  AuthAssets._();

  static const String _base = 'assets/images/auth';

  static const String welcomeHero = '$_base/welcome_hero.svg';
  static const String loginHero = '$_base/login_hero.svg';
  static const String registerHero = '$_base/register_hero.svg';
  static const String logoMark = '$_base/logo_mark.svg';

  static const String featureParent = '$_base/feature_parent.svg';
  static const String featureTeacher = '$_base/feature_teacher.svg';
  static const String featureHealthcare = '$_base/feature_healthcare.svg';
  static const String featureChild = '$_base/feature_child.svg';
  static const String featureSecure = '$_base/feature_secure.svg';

  static String jpegPath(String svgAssetPath) =>
      svgAssetPath.replaceAll('.svg', '.jpg');

  static String? networkUrlFor(String svgAssetPath) {
    switch (svgAssetPath) {
      case welcomeHero:
        return ImageSources.welcomeHero;
      case loginHero:
        return ImageSources.loginHero;
      case registerHero:
        return ImageSources.registerHero;
      case '$_base/register_teacher.svg':
      case '$_base/feature_teacher.svg':
        return ImageSources.registerTeacher;
      case '$_base/register_healthcare.svg':
      case '$_base/feature_healthcare.svg':
        return ImageSources.registerHealthcare;
      case '$_base/register_child.svg':
      case '$_base/feature_child.svg':
        return ImageSources.registerChild;
      case featureParent:
        return ImageSources.featureParent;
      case featureTeacher:
        return ImageSources.featureTeacher;
      case featureHealthcare:
        return ImageSources.featureHealthcare;
      case featureChild:
        return ImageSources.featureChild;
      case featureSecure:
        return ImageSources.featureSecure;
      default:
        return null;
    }
  }

  static String registerHeroForRole(String role) {
    switch (role) {
      case 'Teacher':
        return '$_base/register_teacher.svg';
      case 'Healthcare':
        return '$_base/register_healthcare.svg';
      case 'Child':
        return '$_base/register_child.svg';
      default:
        return registerHero;
    }
  }
}
