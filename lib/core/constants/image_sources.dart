/// Remote JPEG sources for bundled assets (Picsum — stable, free).
/// Used by [tool/download_assets.dart] and runtime network fallbacks.
class ImageSources {
  ImageSources._();

  static const String _picsum = 'https://picsum.photos/seed';

  // Products
  static const String schoolStarterKit = '$_picsum/kidcare-school-kit/640/480.jpg';
  static const String classicPoloUniform = '$_picsum/kidcare-uniform/640/480.jpg';
  static const String stemActivityPack =
      'https://images.unsplash.com/photo-1532094349884-543bc11b234d?auto=format&fit=crop&w=640&q=80';
  static const String vitaminGummies = '$_picsum/kidcare-vitamins/640/480.jpg';
  static const String readingAdventureSet =
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=640&q=80';
  static const String artCraftBox = '$_picsum/kidcare-art-craft/640/480.jpg';
  static const String promoBackToSchool = '$_picsum/kidcare-back-to-school/720/400.jpg';

  // Auth heroes
  static const String welcomeHero =
      'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?auto=format&fit=crop&w=800&q=80';
  static const String loginHero =
      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80';
  static const String registerHero =
      'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=800&q=80';
  static const String registerTeacher =
      'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=800&q=80';
  static const String registerHealthcare =
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=800&q=80';
  static const String registerChild =
      'https://images.unsplash.com/photo-1544776193-352d25ca82cd?auto=format&fit=crop&w=800&q=80';

  // Auth feature tiles (role-specific — matches register heroes)
  static const String featureParent = registerHero;
  static const String featureTeacher = registerTeacher;
  static const String featureHealthcare = registerHealthcare;
  static const String featureChild = registerChild;
  static const String featureSecure =
      'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=480&q=80';
}
