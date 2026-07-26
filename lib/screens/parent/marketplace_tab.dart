import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_branding.dart';
import '../../core/constants/marketplace_assets.dart';
import '../../core/constants/marketplace_catalog.dart';
import '../../core/constants/marketplace_recommendations.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/child_provider.dart';
import '../../widgets/marketplace/product_image.dart';
import '../../widgets/marketplace/cart_icon_button.dart';
import '../../widgets/navigation/dashboard_header_actions.dart';

class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({super.key});

  @override
  State<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<MarketplaceTab> {
  int _selectedCategory = 0;
  String _searchQuery = '';

  List<ProductModel> get _filteredProducts {
    var list = MarketplaceCatalog.products;
    if (_selectedCategory > 0) {
      final label = MarketplaceCatalog.categories[_selectedCategory].label;
      list = list.where((p) => p.category == label).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.subtitle.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardCompactToolbar(
                    trailingActions: [
                      MarketplaceCartIconButton(isDark: isDark),
                    ],
                  ),
                  _buildHeader(context, isDark),
                ],
              ),
            ),
            SliverToBoxAdapter(child: _buildPromoBanner(isDark)),
            SliverToBoxAdapter(child: _buildRecommendations(context, isDark)),
            SliverToBoxAdapter(child: _buildCategoryRow(isDark)),
            if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No products match your search.',
                    style: TextStyle(color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductCard(product: products[index], isDark: isDark),
                    childCount: products.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppBranding.shopName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Books, uniforms, supplies & health essentials',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
              filled: true,
              fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, bool isDark) {
    final children = context.watch<ChildProvider>().children;
    final picks = MarketplaceRecommendations.forChildren(children);
    final headline = MarketplaceRecommendations.headlineFor(children);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.primaryBlue.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: picks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 148,
                child: _ProductCard(
                  product: picks[index],
                  isDark: isDark,
                  compact: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 120,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ProductImage(
                assetPath: MarketplaceAssets.promoBackToSchool,
                networkUrl: MarketplaceAssets.urlPromoBackToSchool,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.85),
                      AppTheme.primaryBlueDark.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Back to School',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Up to 20% off curated bundles.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.local_offer_rounded, color: Colors.white, size: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < MarketplaceCatalog.categories.length; index++)
                    _categoryChip(index, isDark, leadingGap: index > 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryChip(int index, bool isDark, {bool leadingGap = false}) {
    final category = MarketplaceCatalog.categories[index];
    final selected = _selectedCategory == index;

    return Padding(
      padding: EdgeInsets.only(left: leadingGap ? 8 : 0),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: selected ? Colors.white : category.color,
            ),
            const SizedBox(width: 6),
            Text(category.label),
          ],
        ),
        selectedColor: category.color,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: selected ? Colors.white : (isDark ? Colors.grey[300] : AppTheme.textPrimary),
        ),
        side: BorderSide(
          color: selected ? category.color : (isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
        ),
        onSelected: (_) => setState(() => _selectedCategory = index),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isDark;
  final bool compact;

  const _ProductCard({
    required this.product,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = MarketplaceCatalog.accentForCategory(product.category);

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AppRoutes.push(context, AppRoutes.productDetail, arguments: product),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductImage(
                      assetPath: product.imageAsset,
                      networkUrl: product.imageUrl,
                      accent: accent,
                      borderRadius: BorderRadius.circular(12),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.priceDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                          fontSize: compact ? 12 : 13,
                        ),
                      ),
                    ),
                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
