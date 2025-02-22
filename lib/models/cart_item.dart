import 'package:nguat/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
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

  Map<String, dynamic> toJson() => {
    'product_id': int.parse(product.id),
    'name': product.name,
    'price': product.price,
    'quantity': quantity,
    'total': total,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(json['product']),
    quantity: json['quantity'],
  );
}
