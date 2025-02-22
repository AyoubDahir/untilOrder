import 'package:nguat/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  }) {
    // Validate product ID
    if (product.id.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }
    if (int.tryParse(product.id) == null) {
      throw ArgumentError('Invalid product ID format: ${product.id}');
    }
  }

  double get total => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };
}
