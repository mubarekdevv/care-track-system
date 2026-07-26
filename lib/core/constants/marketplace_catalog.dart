import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'marketplace_assets.dart';
import '../theme/app_theme.dart';

class MarketplaceCategory {
  final String label;
  final IconData icon;
  final Color color;

  const MarketplaceCategory(this.label, this.icon, this.color);
}

/// Sample catalog until Firestore `products` collection is wired.
class MarketplaceCatalog {
  MarketplaceCatalog._();

  static const List<MarketplaceCategory> categories = [
    MarketplaceCategory('All', Icons.apps_rounded, AppTheme.primaryBlue),
    MarketplaceCategory('Books', Icons.menu_book_rounded, Color(0xFF6366F1)),
    MarketplaceCategory('Uniforms', Icons.checkroom_rounded, Color(0xFF7ED321)),
    MarketplaceCategory('Supplies', Icons.backpack_rounded, Color(0xFFF59E0B)),
    MarketplaceCategory('Health', Icons.medical_services_rounded, Color(0xFFE2894A)),
  ];
  static const List<ProductModel> products = [
    ProductModel(
      id: 'school-starter-kit',
      name: 'School Starter Kit',
      subtitle: 'Grades K–2 essentials bundle',
      description:
          'Notebook, pencils, erasers, and labels in one parent-approved bundle. Ideal for the first week of school.',
      price: 24.99,
      category: 'Books',
      rating: 4.8,
      imageAsset: MarketplaceAssets.schoolStarterKit,
      imageUrl: MarketplaceAssets.urlSchoolStarterKit,
    ),
    ProductModel(
      id: 'classic-polo-uniform',
      name: 'Classic Polo Uniform',
      subtitle: 'Breathable cotton, navy blue',
      description:
          'Soft cotton polo with reinforced seams. Machine washable and available in multiple youth sizes.',
      price: 18.50,
      category: 'Uniforms',
      rating: 4.6,
      imageAsset: MarketplaceAssets.classicPoloUniform,
      imageUrl: MarketplaceAssets.urlClassicPoloUniform,
    ),
    ProductModel(
      id: 'stem-activity-pack',
      name: 'STEM Activity Pack',
      subtitle: 'Hands-on science for ages 8–12',
      description:
          'Guided experiments with safe materials. Builds curiosity in physics, chemistry, and engineering basics.',
      price: 32.00,
      category: 'Supplies',
      rating: 4.9,
      imageAsset: MarketplaceAssets.stemActivityPack,
      imageUrl: MarketplaceAssets.urlStemActivityPack,
    ),
    ProductModel(
      id: 'vitamin-gummies',
      name: 'Vitamin Gummies',
      subtitle: 'Pediatrician-recommended daily',
      description:
          'Daily multivitamin gummies with no artificial colors. Always consult your healthcare provider before use.',
      price: 14.25,
      category: 'Health',
      rating: 4.7,
      imageAsset: MarketplaceAssets.vitaminGummies,
      imageUrl: MarketplaceAssets.urlVitaminGummies,
    ),
    ProductModel(
      id: 'reading-adventure-set',
      name: 'Reading Adventure Set',
      subtitle: '5 illustrated storybooks',
      description:
          'Age-appropriate stories that support literacy at home. Includes discussion prompts for parents.',
      price: 29.99,
      category: 'Books',
      rating: 4.5,
      imageAsset: MarketplaceAssets.readingAdventureSet,
      imageUrl: MarketplaceAssets.urlReadingAdventureSet,
    ),
    ProductModel(
      id: 'art-craft-box',
      name: 'Art & Craft Box',
      subtitle: 'Crayons, paper, safe scissors',
      description:
          'Creative supplies for classroom and home projects. Rounded-tip scissors for younger children.',
      price: 19.99,
      category: 'Supplies',
      rating: 4.4,
      imageAsset: MarketplaceAssets.artCraftBox,
      imageUrl: MarketplaceAssets.urlArtCraftBox,
    ),
  ];

  static Color accentForCategory(String category) {
    for (final item in categories) {
      if (item.label == category) return item.color;
    }
    return AppTheme.primaryBlue;
  }
}
