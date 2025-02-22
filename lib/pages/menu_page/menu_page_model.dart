import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import '../../services/order_service.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../services/navigation_service.dart';
import '../../widgets/receipt_widget.dart';
import '../../models/order_item.dart';
import 'package:printing/printing.dart';

class MenuPageModel extends ChangeNotifier {
  String? _sessionToken;
  String? _employeeId;
  String? _employeeName;
  int? _userId;
  bool _isLoading = false;
  String? _error;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String? _selectedCategory;
  Set<String> _categories = {};
  final Map<String, CartItem> _cart = {};
  bool _isSubmitting = false;
  String? _successMessage;
  String? _lastOrderId;
  String _searchQuery = '';
  SharedPreferences? _prefs;
  DateTime? _lastFetchTime;
  DateTime? _lastProductsFetch;
  bool _isLoadingProducts = false;

  static const String PRODUCTS_CACHE_KEY = 'cached_products';
  static const String LAST_FETCH_TIME_KEY = 'products_last_fetch_time';
  static const Duration CACHE_DURATION = Duration(hours: 24);
  static const double TAX_RATE = 0.05; // 5% tax rate
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  MenuPageModel({
    String? sessionToken,
    String? employeeId,
    String? userId,
  }) {
    _sessionToken = sessionToken;
    _employeeId = employeeId;
    _userId = int.tryParse(userId ?? '');
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedProducts();
  }

  Future<List<Product>> _loadCachedProducts() async {
    try {
      final cachedData = _prefs?.getString(PRODUCTS_CACHE_KEY);
      if (cachedData != null) {
        final List<dynamic> productsJson = json.decode(cachedData);
        return productsJson.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached products: $e');
    }
    return [];
  }

  Future<void> _cacheProducts() async {
    try {
      if (_prefs != null && _products.isNotEmpty) {
        final productsJson = _products.map((p) => p.toJson()).toList();
        await _prefs!.setString(PRODUCTS_CACHE_KEY, json.encode(productsJson));
        debugPrint('Cached ${_products.length} products');
      }
    } catch (e) {
      debugPrint('Error caching products: $e');
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  String? get selectedCategory => _selectedCategory;
  Set<String> get categories => _categories;
  List<CartItem> get cartItems => _cart.values.toList();
  bool get isCartEmpty => _cart.isEmpty;
  int get cartItemCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  bool get isSubmitting => _isSubmitting;
  String? get employeeName => _employeeName;

  double get subtotal {
    return _cart.values.fold(
        0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get tax => subtotal * TAX_RATE;
  double get total => subtotal + tax;
  String? get successMessage => _successMessage;
  String? get lastOrderId => _lastOrderId;
  double get cartTotal => subtotal + tax;

  // Setters
  set sessionToken(String? value) {
    _sessionToken = value;
    notifyListeners();
  }

  set employeeId(String? value) {
    _employeeId = value;
    notifyListeners();
  }

  set employeeName(String? value) {
    _employeeName = value;
    notifyListeners();
  }

  set userId(String? value) {
    _userId = int.tryParse(value ?? '');
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  Future<void> initState(BuildContext context) async {
    try {
      await initializeLoginState();
      if (_sessionToken != null) {
        await fetchProducts();
      }
    } catch (e) {
      debugPrint('Error in initState: $e');
    }
  }

  void setSelectedCashier(Map<String, dynamic> employee) {
    _employeeId = employee['id'].toString();
    _employeeName = employee['name'];
    notifyListeners();
  }

  void filterProducts(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      // If query is empty, show all products but respect category filter
      _filteredProducts = _selectedCategory == null
          ? List.from(_products)
          : _products
              .where((product) =>
                  product.category.toLowerCase() == _selectedCategory!.toLowerCase())
              .toList();
    } else {
      // Filter by search query and category
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(_searchQuery) ||
            product.description.toLowerCase().contains(_searchQuery) ||
            product.category.toLowerCase().contains(_searchQuery);
        
        return _selectedCategory == null
            ? matchesSearch
            : matchesSearch &&
                product.category.toLowerCase() == _selectedCategory!.toLowerCase();
      }).toList();
    }
    
    // Sort products by name for consistency
    _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      _cart[product.id]!.quantity++;
    } else {
      _cart[product.id] = CartItem(product: product, quantity: 1);
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    if (_cart.containsKey(product.id)) {
      if (_cart[product.id]!.quantity > 1) {
        _cart[product.id]!.quantity--;
      } else {
        _cart.remove(product.id);
      }
      notifyListeners();
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _cart.remove(productId);
    } else {
      _cart[productId]?.quantity = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void incrementQuantity(Product product) {
    addToCart(product);
  }

  void decrementQuantity(Product product) {
    if (_cart.containsKey(product.id)) {
      if (_cart[product.id]!.quantity > 1) {
        _cart[product.id]!.quantity--;
      } else {
        _cart.remove(product.id);
      }
      notifyListeners();
    }
  }

  void removeItemCompletely(Product product) {
    _cart.remove(product.id);
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulated product data for testing
      await Future.delayed(const Duration(seconds: 1));
      _products.clear();
      _products.addAll([
        Product(
          id: '1',
          name: 'Espresso',
          description: 'Strong black coffee',
          price: 2.99,
          imageUrl: 'https://example.com/espresso.jpg',
          type: 'Coffee',
          category: 'Coffee',
        ),
        Product(
          id: '2',
          name: 'Cappuccino',
          description: 'Coffee with steamed milk foam',
          price: 3.99,
          imageUrl: 'https://example.com/cappuccino.jpg',
          type: 'Coffee',
          category: 'Coffee',
        ),
        Product(
          id: '3',
          name: 'Green Tea',
          description: 'Traditional green tea',
          price: 2.49,
          imageUrl: 'https://example.com/green-tea.jpg',
          type: 'Tea',
          category: 'Tea',
        ),
        Product(
          id: '4',
          name: 'Croissant',
          description: 'Buttery, flaky pastry',
          price: 2.99,
          imageUrl: 'https://example.com/croissant.jpg',
          type: 'Pastry',
          category: 'Pastry',
        ),
        Product(
          id: '5',
          name: 'Chocolate Muffin',
          description: 'Rich chocolate muffin',
          price: 2.49,
          imageUrl: 'https://example.com/muffin.jpg',
          type: 'Pastry',
          category: 'Pastry',
        ),
        Product(
          id: '6',
          name: 'Iced Latte',
          description: 'Cold coffee with milk',
          price: 4.49,
          imageUrl: 'https://example.com/iced-latte.jpg',
          type: 'Coffee',
          category: 'Coffee',
        ),
      ]);

      // Update categories
      _categories = _products.map((p) => p.type).toSet();

      // Apply any existing filters
      if (_searchQuery.isNotEmpty) {
        filterProducts(_searchQuery);
      } else if (_selectedCategory != null) {
        _filteredProducts =
            _products.where((p) => p.type == _selectedCategory).toList();
      } else {
        _filteredProducts = List.from(_products);
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeLoginState() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }

      _sessionToken = _prefs!.getString('session_token');
      _employeeId = _prefs!.getString('employee_id');
      _employeeName = _prefs!.getString('employee_name');

      // Handle userId as string
      final savedUserId = _prefs!.getString('user_id');
      if (savedUserId != null && savedUserId.isNotEmpty) {
        _userId = int.tryParse(savedUserId);
      }

      debugPrint('Has session: ${_sessionToken != null}');
      debugPrint('Has employee ID: ${_employeeId != null}');
    } catch (e) {
      debugPrint('Error loading login state: $e');
      rethrow;
    }
  }

  Future<void> submitOrder(BuildContext context) async {
    if (_cart.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return;
    }

    try {
      _isSubmitting = true;
      _error = null;
      notifyListeners();

      debugPrint('Cart items before submission:');
      for (var item in _cart.values) {
        debugPrint('${item.product.name}: ${item.quantity}x \$${item.product.price}');
      }

      await initializeLoginState();

      if (_sessionToken == null || _userId == null || _employeeId == null) {
        throw Exception('Authentication required');
      }

      final orderService = OrderService();
      orderService.sessionToken = _sessionToken;

      // Convert cart items to receipt items with proper typing
      final receiptItems = _cart.values.map((item) => {
        'name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price,
        'total': (item.product.price * item.quantity),
        'product_id': int.parse(item.product.id),
        'full_product_name': item.product.name,
      }).toList();

      // Calculate totals with 5% tax
      final subtotal = receiptItems.fold<double>(
        0.0,
        (sum, item) => sum + ((item['price'] as double) * (item['quantity'] as int)),
      );
      final tax = subtotal * 0.05; // 5% tax
      final total = subtotal + tax;

      // Submit order
      try {
        final response = await orderService.submitOrder(
          receiptItems,
          total,
        );

        if (response['result'] != null) {
          _successMessage = 'Order submitted successfully!';
          _lastOrderId = response['result'][0]['pos_reference'];
          debugPrint('Order submitted successfully with ID: $_lastOrderId');

          // Show receipt dialog immediately after successful order
          if (context.mounted) {
            debugPrint('Showing receipt dialog...');
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) => Dialog(
                child: Container(
                  width: 350,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo
                                Container(
                                  height: 60,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'assets/images/ng.jpg',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Order Details
                                Text(
                                  'Order #${_lastOrderId ?? ""}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: ${DateTime.now().toString().split('.')[0]}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cashier: ${_employeeName ?? "Unknown"}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Divider(height: 32),
                                // Order Items
                                ...receiptItems.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          item['name'].toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'x${item['quantity']}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '\$${double.tryParse(item['price'].toString()) ?? 0.0.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const Divider(height: 32),
                                // Totals
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:'),
                                    Text('\$${subtotal.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tax (5%):'),
                                    Text('\$${tax.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '\$${total.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Action Buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.print, color: Colors.white),
                                label: const Text('Print', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () async {
                                  final pdf = await ReceiptWidget.buildPdf(_lastOrderId ?? '', receiptItems, total);
                                  final bytes = await pdf.save();
                                  await Printing.layoutPdf(
                                    onLayout: (_) => bytes,
                                    format: PdfPageFormat.roll80,
                                  );
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                child: const Text('Close'),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            debugPrint('Receipt dialog shown');
          }
          
          clearCart(); // Clear the cart after successful submission
          notifyListeners();
        } else {
          _error = 'Failed to submit order';
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error showing receipt dialog: $e');
        _error = 'Error submitting order: $e';
        notifyListeners();
      }

    } catch (e) {
      debugPrint('Error submitting order: $e');
      _error = e.toString();

      if (e.toString().contains('Authentication required') ||
          e.toString().contains('Missing login details') ||
          e.toString().contains('Session expired')) {
        // Clear invalid credentials
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('session_token');
        await prefs.remove('user_id');
        await prefs.remove('employee_id');
        await prefs.remove('employee_name');
        
        // Redirect to login
        if (navigatorKey.currentContext != null) {
          Navigator.pushReplacementNamed(
              navigatorKey.currentContext!, '/login');
        }
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> checkLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionToken = prefs.getString('session_token');
      _userId = int.tryParse(prefs.getString('user_id') ?? '');
      _employeeId = prefs.getString('employee_id');
      _employeeName = prefs.getString('employee_name');

      if (_sessionToken == null || _userId == null || _employeeId == null) {
        // Navigate to login
        if (navigatorKey.currentContext != null) {
          Navigator.pushReplacementNamed(
              navigatorKey.currentContext!, '/login');
        }
      }
    } catch (e) {
      debugPrint('Error checking login state: $e');
    }
  }

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (_isLoadingProducts) return;

    try {
      _isLoadingProducts = true;
      _error = null;
      notifyListeners();

      await initializeLoginState();

      final response = await http.get(
        Uri.parse('${OrderService.baseUrl}/api/get_all_products_from_odoo'),
        headers: {
          'Accept': 'application/json',
          'Cookie': _sessionToken ?? '',
        },
      );

      debugPrint('Product API response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success' && data['products'] is List) {
          _products = (data['products'] as List)
              .map((json) => Product.fromJson(json))
              .toList();
          
          // Sort products by name
          _products.sort((a, b) => a.name.compareTo(b.name));
          
          // Extract unique categories
          _categories = _products.map((p) => p.type).toSet();
          
          // Update filtered products
          filterProducts(_searchQuery);
          
          // Cache the products
          await _cacheProducts();
        } else {
          throw Exception('Invalid response format or no products available');
        }
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to fetch products: $e';
      debugPrint('Error fetching products: $e');
      
      // Try to load cached products if available
      final cachedProducts = await _loadCachedProducts();
      if (cachedProducts.isNotEmpty) {
        _products = cachedProducts;
        _categories = _products.map((p) => p.type).toSet();
        filterProducts(_searchQuery);
      }
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      // Clear cart
      clearCart();

      // Clear session data
      _sessionToken = null;
      _employeeId = null;
      _employeeName = null;
      _userId = null;

      // Clear cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_token');
      await prefs.remove('user_id');
      await prefs.remove('employee_id');
      await prefs.remove('employee_name');
      await prefs.remove('products_cache');
      await prefs.remove('orders_cache');

      // Navigate to login
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Still try to navigate to login even if there's an error
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
