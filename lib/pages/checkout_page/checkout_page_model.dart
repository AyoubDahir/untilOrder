import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CheckoutPageModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? error;

  // Form fields
  String name = '';
  String phone = '';
  String address = '';
  String email = '';
  List<Map<String, dynamic>> cartItems = [];
  double total = 0.0;

  void setCartItems(List<Map<String, dynamic>> items) {
    cartItems = items;
    total = items.fold(0.0, (sum, item) => 
      sum + (item['price'] as double) * (item['quantity'] as int));
    notifyListeners();
  }

  Future<bool> placeOrder() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    formKey.currentState!.save();
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8069/api/create_order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customer': {
            'name': name,
            'phone': phone,
            'address': address,
            'email': email,
          },
          'items': cartItems,
          'total': total,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return true;
        } else {
          error = data['message'] ?? 'Failed to place order';
        }
      } else {
        error = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Network error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return false;
  }
}