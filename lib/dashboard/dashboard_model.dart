import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../pages/login_page/login_page_model.dart';
import '../pages/login_page/login_page_widget.dart';

enum OrderStatus { open, paid, done, invoiced, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.open:
        return 'Open';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.done:
        return 'Done';
      case OrderStatus.invoiced:
        return 'Invoiced';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.open:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.green;
      case OrderStatus.done:
        return Colors.blue;
      case OrderStatus.invoiced:
        return Colors.purple;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return OrderStatus.open;
      case 'paid':
        return OrderStatus.paid;
      case 'done':
        return OrderStatus.done;
      case 'invoiced':
        return OrderStatus.invoiced;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.open;
    }
  }
}

class Order {
  final String id;
  final String reference;
  final String date;
  final double total;
  final OrderStatus status;
  final String customerName;

  Order({
    required this.id,
    required this.reference,
    required this.date,
    required this.total,
    required this.status,
    required this.customerName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      reference: json['pos_reference'] ?? '',
      date: json['date_order'] ?? '',
      total: (json['amount_total'] as num).toDouble(),
      status: OrderStatusExtension.fromString(json['state'] ?? 'open'),
      customerName: json['partner_id'] != false
          ? json['partner_id'][1]
          : 'Walk-in Customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pos_reference': reference,
      'date_order': date,
      'amount_total': total,
      'state': status.toString().split('.').last,
      'partner_id': [0, customerName],
    };
  }
}

class DashboardModel extends ChangeNotifier {
  final LoginPageModel? loginPageModel;
  final OrderService _orderService = OrderService();
  List<Order> _recentOrders = [];
  bool _isLoading = false;
  String? _error;
  OrderStatus? _selectedStatus;
  SharedPreferences? _prefs;
  DateTime? _lastFetchTime;
  Timer? _refreshTimer;
  static const Duration refreshInterval = Duration(minutes: 1);
  static const String RECENT_ORDERS_CACHE_KEY = 'recentOrders';
  static const String LAST_FETCH_TIME_KEY = 'lastOrdersFetchTime';
  List<dynamic> _orders = [];

  DashboardModel({this.loginPageModel}) {
    debugPrint('Initializing DashboardModel...');
    _initPrefs().then((_) {
      debugPrint('SharedPreferences initialized');
      _initializeData();
    }).catchError((error) {
      debugPrint('Error initializing DashboardModel: $error');
      _error = 'Failed to initialize dashboard: $error';
      notifyListeners();
    });
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedOrders();
  }

  Future<void> _loadCachedOrders() async {
    try {
      final lastFetchTimeStr = _prefs?.getString(LAST_FETCH_TIME_KEY);
      if (lastFetchTimeStr != null) {
        _lastFetchTime = DateTime.parse(lastFetchTimeStr);
        final cachedData = _prefs?.getString(RECENT_ORDERS_CACHE_KEY);
        if (cachedData != null) {
          final List<dynamic> ordersJson = json.decode(cachedData);
          _recentOrders =
              ordersJson.map((json) => Order.fromJson(json)).toList();
          notifyListeners();
          debugPrint('Loaded ${_recentOrders.length} orders from cache');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached orders: $e');
    }
  }

  Future<void> _cacheOrders() async {
    try {
      final ordersJson = _recentOrders.map((o) => o.toJson()).toList();
      await _prefs?.setString(RECENT_ORDERS_CACHE_KEY, json.encode(ordersJson));
      await _prefs?.setString(
          LAST_FETCH_TIME_KEY, DateTime.now().toIso8601String());
      debugPrint('Orders cached successfully');
    } catch (e) {
      debugPrint('Error caching orders: $e');
    }
  }

  void _initializeData() {
    fetchOrders();
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) => fetchOrders());
  }

  Future<void> fetchOrders() async {
    if (_isLoading) {
      debugPrint('Already fetching orders, skipping...');
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Authenticating before fetching orders...');
      await _orderService.authenticate();

      if (_orderService.sessionToken == null) {
        throw Exception('No valid session token available');
      }

      debugPrint('Fetching orders with session token: ${_orderService.sessionToken}');
      final response = await http.post(
        Uri.parse('${OrderService.baseUrl}/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_orderService.sessionToken != null)
            'Cookie': _orderService.sessionToken!,
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "pos.order",
            "method": "search_read",
            "args": [
              [], // Empty domain to get all orders
              [
                "id",
                "pos_reference",
                "date_order",
                "amount_total",
                "state",
                "partner_id",
              ]
            ],
            "kwargs": {
              "context": _orderService.userContext ??
                  {"lang": "en_US", "tz": "Africa/Nairobi", "uid": 2},
              "limit": 20,
              "order": "date_order desc"
            }
          },
          "id": DateTime.now().millisecondsSinceEpoch
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          _recentOrders = (data['result'] as List)
              .map((order) => Order.fromJson(order))
              .toList();
          await _cacheOrders();
          debugPrint('Successfully fetched ${_recentOrders.length} orders');
        } else if (data['error'] != null) {
          _error = data['error']['data']['message'] ?? 'Failed to fetch orders';
          debugPrint('Error from server: $_error');
        }
      } else {
        _error = 'Server error: ${response.statusCode}';
        debugPrint('HTTP error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      _error = 'Error loading orders: $e';
      debugPrint('Error fetching orders: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getters
  List<Order> get recentOrders => _selectedStatus == null
      ? _recentOrders
      : _recentOrders
          .where((order) => order.status == _selectedStatus)
          .toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderStatus? get selectedStatus => _selectedStatus;
  DateTime? get lastFetchTime => _lastFetchTime;
  List<dynamic> get orders => _orders;

  // Set status filter
  void setStatusFilter(OrderStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    await fetchOrders();
  }

  Future<void> clearOrderCache() async {
    await _prefs?.remove(RECENT_ORDERS_CACHE_KEY);
    await _prefs?.remove(LAST_FETCH_TIME_KEY);
    _recentOrders.clear();
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    try {
      debugPrint('Starting logout process...');

      final bool? shouldLogout = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 10),
                Text('Logout'),
              ],
            ),
            content: Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Logout'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        debugPrint('User confirmed logout');

        // Show loading
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );
        }

        // Clear Odoo session
        try {
          final response = await http.post(
            Uri.parse('https://nagaadhalls.com/web/session/destroy'),
            headers: {
              'Content-Type': 'application/json',
              if (_orderService.sessionToken != null)
                'Cookie': _orderService.sessionToken!,
            },
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'call',
            }),
          );
          debugPrint('Odoo session destroyed: ${response.statusCode}');
        } catch (e) {
          debugPrint('Error destroying Odoo session: $e');
        }

        // Clear all data
        if (_prefs != null) {
          await _prefs!.remove('session_token');
          await _prefs!.remove('user_id');
          await _prefs!.remove('employee_id');
          await _prefs!.remove('employee_name');
          await _prefs!.remove('selectedEmployee');
          await _prefs!.remove('cashier_pin');
          await _prefs!.remove(RECENT_ORDERS_CACHE_KEY);
          await _prefs!.remove(LAST_FETCH_TIME_KEY);
        }

        // Reset all state
        _orderService.sessionToken = null;
        _orderService.userContext = null;
        _recentOrders = [];
        _error = null;
        _selectedStatus = null;
        _lastFetchTime = null;
        _orders = [];
        _refreshTimer?.cancel();

        if (context.mounted) {
          // Pop loading dialog
          Navigator.of(context).pop();

          // Navigate to login
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out. Please try again.')),
        );
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
