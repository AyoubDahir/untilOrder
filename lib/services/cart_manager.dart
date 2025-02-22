import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import 'order_service.dart';

class CartItem {
  final Product product;
  int quantity;
  double get total => product.price * quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(json['product']),
    quantity: json['quantity'],
  );
}

class CartManager with ChangeNotifier {
  static const String _cartKey = 'cart_items';
  static const String _orderHistoryKey = 'order_history';
  final Map<int, CartItem> _items = {};
  final List<Map<String, dynamic>> _orderHistory = [];
  final OrderService _orderService = OrderService();
  
  CartManager() {
    _loadCart();
    _loadOrderHistory();
  }

  // Getters
  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.05; // 5% tax
  double get total => subtotal + tax;
  List<Map<String, dynamic>> get orderHistory => _orderHistory;

  // Cart Operations
  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(product: product);
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(int productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity--;
      } else {
        _items.remove(productId);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void removeItemCompletely(int productId) {
    _items.remove(productId);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  // Order History
  void addToOrderHistory(Map<String, dynamic> order) {
    _orderHistory.insert(0, order);
    if (_orderHistory.length > 100) { // Keep last 100 orders
      _orderHistory.removeLast();
    }
    _saveOrderHistory();
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitOrder(Map<String, dynamic> employeeData) async {
    try {
      if (_items.isEmpty) {
        return {
          'status': 'error',
          'message': 'Cart is empty',
        };
      }

      final orderLines = _items.entries.map((entry) {
        final item = entry.value;
        final productId = int.tryParse(item.product.id.toString());
        if (productId == null) {
          throw Exception('Invalid product ID: ${item.product.id}');
        }
        return [0, 0, {
          'product_id': productId,
          'qty': item.quantity,
          'price_unit': item.product.price,
          'discount': 0,
          'tax_ids': [[6, false, []]],
          'price_subtotal': item.product.price * item.quantity,
          'price_subtotal_incl': item.product.price * item.quantity,
          'notice': '',
          'full_product_name': item.product.name,
        }];
      }).toList();

      final totalAmount = total;
      
      // Ensure employee ID is handled as string
      final employeeId = employeeData['id']?.toString() ?? '';
      if (employeeId.isEmpty) {
        return {
          'status': 'error',
          'message': 'Invalid employee ID',
        };
      }

      debugPrint('Cart contents before submission: ${_items.entries.map((e) => 
        "${e.value.product.name}: ${e.value.quantity}x\$${e.value.product.price}").join(", ")}');

      final result = await _orderService.createOrder(
        orderLines: orderLines,
        totalAmount: totalAmount,
        employeeId: employeeId,
      );

      if (result['status'] == 'success') {
        await clearCart();
      }

      return result;
    } catch (e) {
      debugPrint('Order submission error: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Persistence
  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      if (cartJson != null) {
        final List<dynamic> cartList = jsonDecode(cartJson);
        _items.clear();
        for (var item in cartList) {
          final cartItem = CartItem.fromJson(item);
          _items[cartItem.product.id] = cartItem;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartList = _items.values.map((item) => item.toJson()).toList();
      await prefs.setString(_cartKey, jsonEncode(cartList));
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  Future<void> _loadOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_orderHistoryKey);
      if (historyJson != null) {
        final List<dynamic> history = jsonDecode(historyJson);
        _orderHistory.clear();
        _orderHistory.addAll(history.cast<Map<String, dynamic>>());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading order history: $e');
    }
  }

  Future<void> _saveOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_orderHistoryKey, jsonEncode(_orderHistory));
    } catch (e) {
      debugPrint('Error saving order history: $e');
    }
  }
}
