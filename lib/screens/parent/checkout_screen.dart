import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/marketplace_order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/auth/auth_primary_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final order = MarketplaceOrder(
        parentId: user.uid,
        parentName: user.fullName,
        email: user.email,
        phone: _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        items: cart.toOrderItems(),
        subtotal: cart.subtotal,
        createdAt: DateTime.now(),
      );

      final orderId = await DatabaseService().placeMarketplaceOrder(order.toMap());
      final placedOrder = MarketplaceOrder(
        id: orderId,
        parentId: order.parentId,
        parentName: order.parentName,
        email: order.email,
        phone: order.phone,
        deliveryAddress: order.deliveryAddress,
        items: order.items,
        subtotal: order.subtotal,
        createdAt: order.createdAt,
        status: order.status,
      );
      await cart.clear();

      if (!mounted) return;
      Navigator.of(context).popUntil(
        (route) => route.isFirst || route.settings.name == AppRoutes.parentHome,
      );
      AppRoutes.push(context, AppRoutes.orderDetail, arguments: placedOrder);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order placed! Track delivery in My Orders.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.softGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => AppRoutes.push(context, AppRoutes.orderDetail, arguments: placedOrder),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not place order. Please try again. ($e)'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.warmNeutral,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _SectionTitle(title: 'Delivery details'),
            const SizedBox(height: 12),
            _ReadOnlyField(label: 'Name', value: user?.fullName ?? 'Parent'),
            const SizedBox(height: 12),
            _ReadOnlyField(label: 'Email', value: user?.email ?? ''),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(isDark, hint: '+1 555 000 0000', label: 'Phone'),
              validator: (val) {
                if (val == null || val.trim().length < 7) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: _inputDecoration(isDark, hint: 'Street, city, postal code', label: 'Delivery address'),
              validator: (val) {
                if (val == null || val.trim().length < 8) {
                  return 'Enter your full delivery address';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Order summary'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
              ),
              child: Column(
                children: [
                  for (final item in cart.items) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}× ${item.product.name}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${item.lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '\$${cart.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Shipping calculated at confirmation. Demo checkout — no payment charged.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Place Order',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _placeOrder,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, {required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark ? AppTheme.darkSurface : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : AppTheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
