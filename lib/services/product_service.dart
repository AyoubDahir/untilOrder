import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  static const String baseUrl = 'http://localhost:8069';
  static const String productEndpoint = '/api/get_all_products_from_odoo';
  static const Duration cacheDuration = Duration(minutes: 5);

  final Map<String, List<Product>> _cache = {};
  final Map<String, List<Product>> _categoryCache = {};

  Future<List<Product>> getProducts() async {
    try {
      final cacheKey = 'all_products';
      if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
        print('Returning products from cache');
        return _cache[cacheKey]!;
      }

      final response = await http.get(
        Uri.parse('$baseUrl$productEndpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((json) => Product.fromJson(json)).toList();
        _cache[cacheKey] = products;
        print('Fetched products: $products');
        return products;
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  Future<List<Product>> searchProducts({
    String? name,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      var queryParams = <String, String>{};
      if (name != null) queryParams['name'] = name;
      if (category != null) queryParams['category'] = category;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();

      final uri = Uri.parse('$baseUrl$productEndpoint').replace(queryParameters: queryParams);
      final cacheKey = uri.toString();

      if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isNotEmpty) {
        print('Returning products from cache');
        return _cache[cacheKey]!;
      }

      if (category != null) {
        print('Searching for category: $category');
        print('Available categories in cache: ${_categoryCache.keys}');
        final categoryCacheKey = 'category:$category';
        if (_categoryCache.containsKey(categoryCacheKey)) {
          print('Found ${_categoryCache[categoryCacheKey]!.length} products in category cache for key: $categoryCacheKey');
          final categoryProducts = _categoryCache[categoryCacheKey]!;
          print('First 3 products in this category: ${categoryProducts.take(3).map((p) => p.name).toList()}');
          List<Product> filteredProducts = categoryProducts;
          if (name != null) {
            print('Filtering by name: $name');
            filteredProducts = filteredProducts.where((product) => product.name.toLowerCase().contains(name.toLowerCase())).toList();
            print('Products after name filter: ${filteredProducts.length}');
          }
          if (minPrice != null || maxPrice != null) {
            print('Filtering by price range: $minPrice - $maxPrice');
            filteredProducts = filteredProducts.where((product) => (minPrice == null || product.price >= minPrice) && (maxPrice == null || product.price <= maxPrice)).toList();
            print('Products after price filter: ${filteredProducts.length}');
          }
          print('Returning ${filteredProducts.length} filtered products from cache');
          return filteredProducts;
        } else {
          print('No products found in category cache for key: $categoryCacheKey');
        }
      }

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((json) => Product.fromJson(json)).toList();
        _cache[cacheKey] = products;
        if (category != null) {
          print('Caching ${products.length} products for category: $category');
          _categoryCache['category:$category'] = products;
        }
        print('Fetched ${products.length} products from API');
        return products;
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching products: $e');
      throw Exception('Error searching products: $e');
    }
  }

  void clearCache() {
    _cache.clear();
    _categoryCache.clear();
    print('Cache cleared');
  }
}
