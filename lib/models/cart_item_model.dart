import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get lineTotal => product.price * quantity;

  CartItem copyWith({ProductModel? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final productMap = map['product'] as Map<String, dynamic>? ?? {};
    final productId = productMap['id']?.toString() ?? '';
    return CartItem(
      product: ProductModel.fromMap(productMap, productId),
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 1,
    );
  }
}
