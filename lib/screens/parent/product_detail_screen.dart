import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/marketplace_catalog.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/marketplace/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  ProductModel get product => widget.product;

  Color get _accent => MarketplaceCatalog.accentForCategory(product.category);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Product Details'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageHero(isDark),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Flexible(
                        child: Chip(
                          label: Text(
                            product.category,
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor: _accent.withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About this item',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      height: 1.55,
                      color: isDark ? Colors.grey[300] : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildQuantityRow(isDark),
                ],
              ),
            ),
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildImageHero(bool isDark) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ProductImage(
        assetPath: product.imageAsset,
        networkUrl: product.imageUrl,
        accent: _accent,
        borderRadius: BorderRadius.circular(20),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildQuantityRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Row(
        children: [
          const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final total = product.price * _quantity;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 3,
              child: FilledButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                label: const Text('Add to Cart'),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    context.read<CartProvider>().addProduct(product, quantity: _quantity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity × ${product.name} to cart'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () => AppRoutes.push(context, AppRoutes.cart),
        ),
      ),
    );
  }
}
