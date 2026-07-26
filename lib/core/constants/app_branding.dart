/// Public-facing product name and taglines shown in the UI.
class AppBranding {
  AppBranding._();

  /// Full product name — clear about child & student scope.
  static const String name = 'Child & Student Care';

  /// Stacked logo lines (welcome / marketing screens).
  static const String nameLine1 = 'Child & Student';
  static const String nameLine2 = 'Care & Tracking';

  /// Short label for tight headers (drawer hero, dashboard toolbar).
  static const String headerLabel = 'Care & Track';

  static const String tagline =
      'Child & student tracking and management in one place';

  static const String shopName = 'Family Shop';

  static String welcomeHeadline({String? prefix}) =>
      prefix != null ? '$prefix $name' : 'Welcome to $name';
}
