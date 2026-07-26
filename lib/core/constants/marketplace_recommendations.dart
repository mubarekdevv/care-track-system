import '../../models/child_model.dart';
import '../../models/product_model.dart';
import 'marketplace_catalog.dart';

/// Picks marketplace products based on enrolled children's ages.
class MarketplaceRecommendations {
  MarketplaceRecommendations._();

  static List<ProductModel> forChildren(List<ChildModel> children) {
    if (children.isEmpty) {
      return MarketplaceCatalog.products.take(3).toList();
    }

    final youngest = children.map((c) => c.age).reduce((a, b) => a < b ? a : b);
    final oldest = children.map((c) => c.age).reduce((a, b) => a > b ? a : b);

    final ids = <String>{};

    if (youngest <= 7) {
      ids.addAll(['school-starter-kit', 'reading-adventure-set', 'art-craft-box']);
    }
    if (oldest >= 8) {
      ids.addAll(['stem-activity-pack', 'reading-adventure-set']);
    }
    ids.add('classic-polo-uniform');
    if (children.any((c) => c.vaccinations.length < 3)) {
      ids.add('vitamin-gummies');
    }

    final picked = MarketplaceCatalog.products.where((p) => ids.contains(p.id)).toList();
    if (picked.length >= 3) return picked.take(4).toList();

    for (final product in MarketplaceCatalog.products) {
      if (picked.length >= 4) break;
      if (!picked.any((p) => p.id == product.id)) picked.add(product);
    }

    return picked;
  }

  static String headlineFor(List<ChildModel> children) {
    if (children.isEmpty) return 'Popular for families';
    if (children.length == 1) {
      return 'Recommended for ${children.first.name.split(' ').first}';
    }
    return 'Recommended for your children';
  }
}
