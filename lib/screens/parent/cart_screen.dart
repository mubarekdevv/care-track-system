import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_branding.dart';
import '../../core/constants/marketplace_catalog.dart';
import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/marketplace/product_image.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Your Cart'),
        centerTitle: true,
      ),
      body: !cart.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : cart.isEmpty
              ? _EmptyCart(isDark: isDark)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _CartLineCard(item: item, isDark: isDark);
                        },
                      ),
                    ),
                    _CartSummaryBar(
                      isDark: isDark,
                      subtotal: cart.subtotal,
                      itemCount: cart.itemCount,
                    ),
                  ],
                ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final bool isDark;

  const _EmptyCart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 56,
              color: isDark ? Colors.grey[600] : AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse the ${AppBranding.shopName} and add books, uniforms, or supplies.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey[400] : AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  final CartItem item;
  final bool isDark;

  const _CartLineCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final accent = MarketplaceCatalog.accentForCategory(item.product.category);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: ProductImage(
              assetPath: item.product.imageAsset,
              networkUrl: item.product.imageUrl,
              accent: accent,
              borderRadius: BorderRadius.circular(12),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item.product.priceDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: item.quantity > 1
                          ? () => cart.updateQuantity(item.product.id, item.quantity - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      '\$${item.lineTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => cart.removeProduct(item.product.id),
            icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  final bool isDark;
  final double subtotal;
  final int itemCount;

  const _CartSummaryBar({
    required this.isDark,
    required this.subtotal,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => AppRoutes.push(context, AppRoutes.checkout),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
