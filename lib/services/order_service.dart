import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/receipt_widget.dart';

class OrderService {
  static const String baseUrl = 'https://nagaadhalls.com';
  String? sessionToken;
  Map<String, dynamic>? userContext;

  Future<void> authenticate() async {
    if (sessionToken != null) {
      debugPrint('Using existing session token');
      return;
    }

    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final prefs = await SharedPreferences.getInstance();
        sessionToken = prefs.getString('session_token');
        final contextStr = prefs.getString('user_context');
        if (contextStr != null) {
          userContext = jsonDecode(contextStr);
          debugPrint('Loaded cached user context: $userContext');
        }

        if (sessionToken == null) {
          debugPrint('Authenticating with Odoo server at $baseUrl...');
          final authBody = {
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "db": "postgres",
              "login": "admin",
              "password": "2025"
            },
            "id": 1
          };
          debugPrint('Auth request body: ${jsonEncode(authBody)}');

          final response = await http.post(
            Uri.parse('$baseUrl/web/session/authenticate'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(authBody),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['result'] != null) {
              final cookies = response.headers['set-cookie'];
              if (cookies != null) {
                sessionToken = cookies;
                userContext = data['result']['user_context'];
                
                // Save to preferences
                if (sessionToken != null) {
                  await prefs.setString('session_token', sessionToken!);
                  await prefs.setString('user_context', jsonEncode(userContext));
                  debugPrint('Authentication successful, saved session token: $sessionToken');
                  debugPrint('Saved user context: $userContext');
                } else {
                  throw Exception('No session token received from server');
                }
                return; // Success, exit the retry loop
              }
            }
            throw Exception('Authentication failed: ${data['error']?['data']?['message'] ?? 'Invalid response format'}');
          } else {
            throw Exception('Authentication failed with status code: ${response.statusCode}');
          }
        } else {
          debugPrint('Using cached session token: $sessionToken');
          return;
        }
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          throw Exception('Authentication failed after $maxRetries attempts: $e');
        }
        // Wait before retrying with exponential backoff
        await Future.delayed(Duration(seconds: math.pow(2, retryCount).toInt()));
      }
    }
  }

  Future<Map<String, dynamic>?> _getPosConfig() async {
    try {
      debugPrint('Getting POS config...');
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': sessionToken!,
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "pos.config",
            "method": "search_read",
            "args": [[]],
            "kwargs": {
              "fields": ["id", "name", "current_session_id", "pos_session_state"],
              "context": userContext ?? {
                "lang": "en_US",
                "tz": "Africa/Nairobi",
                "uid": 2
              }
            }
          }
        }),
      );

      debugPrint('POS config response status: ${response.statusCode}');
      debugPrint('POS config response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'] is List && data['result'].isNotEmpty) {
          return data['result'][0];
        } else {
          // If no config found, create a default one
          return await _createDefaultPosConfig();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting POS config: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _createDefaultPosConfig() async {
    try {
      debugPrint('Creating default POS config...');
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': sessionToken!,
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "pos.config",
            "method": "create",
            "args": [{
              "name": "Mobile POS",
              "receipt_header": "Nagaad Restaurant",
              "receipt_footer": "Thank you for your visit!",
            }],
            "kwargs": {
              "context": userContext ?? {
                "lang": "en_US",
                "tz": "Africa/Nairobi",
                "uid": 2
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          // Get the newly created config details
          return _getPosConfig();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error creating default POS config: $e');
      return null;
    }
  }

  Future<int?> _getCurrentPosSession() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (sessionToken != null) 'Cookie': sessionToken!,
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'pos.session',
            'method': 'search_read',
            'args': [],
            'kwargs': {
              'context': userContext,
              'domain': [['state', '=', 'opened']],
              'fields': ['id', 'name', 'config_id'],
              'limit': 1
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          return data['result'][0]['id'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting POS session: $e');
      return null;
    }
  }

  Future<int> _createPosSession(int configId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/web/dataset/call_kw'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (sessionToken != null) 'Cookie': sessionToken!,
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'pos.session',
          'method': 'create',
          'args': [{
            'config_id': configId,
            'user_id': userContext?['uid'],
          }],
          'kwargs': {'context': userContext}
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        return data['result'];
      }
      throw Exception('Failed to create POS session');
    }
    throw Exception('Failed to create POS session: ${response.statusCode}');
  }

  Future<int> _getNextSequenceNumber(int sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (sessionToken != null) 'Cookie': sessionToken!,
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'pos.session',
            'method': 'read',
            'args': [sessionId],
            'kwargs': {
              'fields': ['sequence_number'],
              'context': userContext,
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          final currentSequence = data['result'][0]['sequence_number'] as int? ?? 0;
          return currentSequence + 1;
        }
      }
      return 1; // Default to 1 if we can't get the sequence
    } catch (e) {
      debugPrint('Error getting sequence number: $e');
      return 1; // Default to 1 on error
    }
  }

  Future<int?> _getExistingPricelist() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (sessionToken != null) 'Cookie': sessionToken!,
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "pos.payment.method",
            "method": "search_read",
            "args": [[]],
            "kwargs": {
              "context": userContext ?? {
                "lang": "en_US",
                "tz": "Africa/Nairobi",
                "uid": 2
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'] is List && data['result'].isNotEmpty) {
          return data['result'][0]['id'] as int;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting payment methods: $e');
      return null;
    }
  }

  Future<bool> _updatePosConfig(int pricelistId) async {
    try {
      debugPrint('Updating POS config with pricelist ID: $pricelistId');
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (sessionToken != null) 'Cookie': sessionToken!,
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'pos.config',
            'method': 'write',
            'args': [
              [9], // Your POS config ID
              {
                'pricelist_id': pricelistId,
                'available_pricelist_ids': [(4, pricelistId, 0)],
                'use_pricelist': true,
              }
            ],
            'kwargs': {'context': userContext}
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Update POS config response: $data');
        return data['result'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating POS config: $e');
      return false;
    }
  }

  Future<int?> _getPricelistFromConfig(int configId) async {
    try {
      debugPrint('Getting pricelist for config ID: $configId');
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (sessionToken != null) 'Cookie': sessionToken!,
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'pos.config',
            'method': 'read',
            'args': [configId],
            'kwargs': {
              'fields': ['pricelist_id', 'available_pricelist_ids'],
              'context': userContext,
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Pricelist response: $data');
        
        if (data['result'] != null && data['result'].isNotEmpty) {
          final configData = data['result'][0];
          
          // Try to get pricelist_id first
          if (configData['pricelist_id'] != null && configData['pricelist_id'] != false) {
            if (configData['pricelist_id'] is List) {
              return configData['pricelist_id'][0] as int;
            } else if (configData['pricelist_id'] is int) {
              return configData['pricelist_id'] as int;
            }
          }
          
          // Fall back to first available pricelist
          if (configData['available_pricelist_ids'] != null && 
              configData['available_pricelist_ids'] is List && 
              configData['available_pricelist_ids'].isNotEmpty) {
            return configData['available_pricelist_ids'][0] as int;
          }

          // If no pricelist found, try to get an existing one
          return await _getExistingPricelist();
        }
      }
      debugPrint('No pricelist found in config response');
      return await _getExistingPricelist(); // Try one last time
    } catch (e) {
      debugPrint('Error getting pricelist: $e');
      return null;
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now().toUtc();
    return now.toIso8601String().replaceAll('T', ' ').substring(0, 19);
  }

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> orderLines,
    String? customerName,
    required double totalAmount,
    required String employeeId,
  }) async {
    try {
      // Authenticate first if needed
      if (sessionToken == null) {
        await authenticate();
      }

      // Get latest opened session
      final Map<String, dynamic>? sessionInfo = await _getPosConfig();
      if (sessionInfo == null || sessionInfo['id'] == null) {
        throw Exception('No active POS session found. Please open a session in Odoo.');
      }

      final configId = sessionInfo['id'] as int;
      final currencyId = sessionInfo['currency_id'] as int;

      // Get payment methods
      final paymentMethodId = await _getExistingPricelist();
      if (paymentMethodId == null) {
        throw Exception('No payment methods available for this session');
      }

      final taxRate = 0.05; // 5% tax
      final totalTax = totalAmount * taxRate;
      final totalWithTax = totalAmount + totalTax;
      final dateOrder = _getFormattedDate();
      final uid = "POS-${DateTime.now().millisecondsSinceEpoch}";

      // Convert employeeId to int for the API
      final employeeIdInt = int.tryParse(employeeId);
      if (employeeIdInt == null) {
        throw Exception('Invalid employee ID format');
      }

      // Log order lines for debugging
      debugPrint('Processing order lines: ${jsonEncode(orderLines)}');
      
      // Validate product IDs
      for (var line in orderLines) {
        if (line['product_id'] == null) {
          throw Exception('Product ID cannot be null for product: ${line['name']}');
        }
      }

      final orderData = {
        "data": {
          "amount_paid": totalWithTax,
          "amount_return": 0,
          "amount_tax": totalTax,
          "amount_total": totalWithTax,
          "date_order": dateOrder,
          "creation_date": dateOrder,
          "fiscal_position_id": false,
          "pricelist_id": false,
          "state": "draft",
          "lines": orderLines.map((line) => [0, 0, {
            "discount": 0,
            "id": 0,
            "pack_lot_ids": [],
            "price_unit": line['price_unit'],
            "product_id": line['product_id'],  // Already an integer from CartManager
            "price_subtotal": line['price_unit'] * line['quantity'],
            "price_subtotal_incl": line['price_unit'] * line['quantity'] * (1 + taxRate),
            "qty": line['quantity'],
            "tax_ids": [[6, false, []]],
            "notice": "",
            "name": line['name'], // Use just the product name
            "full_product_name": line['name'], // Use just the product name for consistency
          }]).toList(),
          "name": uid,
          "partner_id": false,
          "pos_session_id": await _getCurrentPosSession(),
          "sequence_number": 1,
          "statement_ids": [],
          "uid": uid,
          "user_id": 2,
          "employee_id": int.parse(await SharedPreferences.getInstance().then((prefs) => prefs.getString('employee_id') ?? '1')),
          "config_id": configId,
        },
        "id": uid,
        "to_invoice": false
      };

      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (sessionToken != null) 'Cookie': sessionToken!,
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "pos.order",
            "method": "create_from_ui",
            "args": [orderData],
            "kwargs": {
              "context": userContext ?? {
                "lang": "en_US",
                "tz": "Africa/Nairobi",
                "uid": 2
              }
            }
          },
          "id": DateTime.now().millisecondsSinceEpoch
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          final orderResult = data['result'];
          return {
            'status': 'success',
            'data': {
              'order_id': orderResult['id'],
              'pos_reference': orderResult['pos_reference'],
              'amount_total': totalWithTax,
              'date_order': dateOrder,
              'state': 'draft'
            }
          };
        } else if (data['error'] != null) {
          if (data['error']['message']?.contains('Session expired') ?? false) {
            // Session expired, retry once after re-authentication
            sessionToken = null;
            userContext = null;
            return createOrder(
              orderLines: orderLines,
              customerName: customerName,
              totalAmount: totalAmount,
              employeeId: employeeId,
            );
          }
          throw Exception(data['error']['data']?['message'] ?? 'Failed to create order');
        }
      }
      
      throw Exception('Failed to create order: ${response.statusCode}');
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
        'data': null
      };
    }
  }

  Future<Map<String, dynamic>> submitOrder(
    List<Map<String, dynamic>> items,
    double total,
  ) async {
    try {
      await authenticate();

      if (sessionToken == null) {
        throw Exception('No valid session token');
      }

      // Get latest opened session
      final sessionInfo = await getLatestSession();
      final configId = sessionInfo['config_id'][0];
      final sessionId = sessionInfo['id'];

      debugPrint('Using session ID: $sessionId');

      final taxRate = 0.05; // 5% tax
      final totalTax = total * taxRate;
      final totalWithTax = total + totalTax;
      final dateOrder = _getFormattedDate();
      final uid = "POS-${DateTime.now().millisecondsSinceEpoch}";

      // Format order lines
      final orderLines = items.map((item) {
        final productId = item['product_id'] is int 
            ? item['product_id'] 
            : int.parse(item['product_id'].toString());
        
        final price = item['price'] is double 
            ? item['price'] 
            : double.parse(item['price'].toString());
        
        final quantity = item['quantity'] is int 
            ? item['quantity'] 
            : int.parse(item['quantity'].toString());

        return [0, 0, {
          "discount": 0,
          "pack_lot_ids": [],
          "price_unit": price,
          "product_id": productId,
          "price_subtotal": price * quantity,
          "price_subtotal_incl": price * quantity * (1 + taxRate),
          "qty": quantity,
          "tax_ids": [[6, false, []]],
          "name": item['name'] ?? '',
        }];
      }).toList();

      debugPrint('Preparing order data...');
      final orderData = {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "model": "pos.order",
          "method": "create_from_ui",
          "args": [[{
            "data": {
              "amount_paid": totalWithTax,
              "amount_return": 0,
              "amount_tax": totalTax,
              "amount_total": totalWithTax,
              "date_order": dateOrder,
              "creation_date": dateOrder,
              "fiscal_position_id": false,
              "pricelist_id": false,
              "state": "open",
              "lines": orderLines,
              "name": uid,
              "partner_id": false,
              "pos_session_id": sessionId,
              "sequence_number": 1,
              "statement_ids": [],
              "uid": uid,
              "user_id": userContext?['uid'] ?? 2,
              "employee_id": int.parse(await SharedPreferences.getInstance().then((prefs) => prefs.getString('employee_id') ?? '1')),
              "config_id": configId,
            },
            "id": uid,
            "to_invoice": false
          }]],
          "kwargs": {"context": userContext}
        },
        "id": DateTime.now().millisecondsSinceEpoch
      };

      debugPrint('Submitting order...');
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': sessionToken!,
        },
        body: jsonEncode(orderData),
      );

      debugPrint('Order submission response status: ${response.statusCode}');
      debugPrint('Order submission response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          final orderResult = data['result'][0];
          return {
            'status': 'success',
            'data': {
              'order_id': orderResult,
              'pos_reference': orderResult['pos_reference'],
              'amount_total': totalWithTax
            }
          };
        } else if (data['error'] != null) {
          // If session expired, try to authenticate again
          if (data['error']['message']?.contains('Session') ?? false) {
            sessionToken = null;
            userContext = null;
            return submitOrder(items, total);
          }
          throw Exception(data['error']['data']?['message'] ?? 'Failed to create order');
        }
        throw Exception('Unknown error occurred');
      } else {
        throw Exception('Failed to submit order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error submitting order: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLatestSession() async {
    try {
      if (userContext == null) {
        await authenticate();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (sessionToken != null) 'Cookie': sessionToken!,
        },
        body: jsonEncode({
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "model": "pos.session",
            "method": "search_read",
            "args": [
              [["state", "=", "opened"]],
              ["id", "config_id", "currency_id", "name", "state"]
            ],
            "kwargs": {
              "context": userContext ?? {
                "lang": "en_US",
                "tz": "Africa/Nairobi",
                "uid": 2
              },
              "limit": 1,
              "order": "create_date desc"
            }
          },
          "id": DateTime.now().millisecondsSinceEpoch
        }),
      );

      debugPrint('Session info response status: ${response.statusCode}');
      debugPrint('Session info response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          return data['result'][0];
        }
        throw Exception('No open POS session found. Please open a session in Odoo first.');
      }
      throw Exception('Failed to get session info');
    } catch (e) {
      debugPrint('Error getting session info: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyEmployeePin(String name, String pin) async {
    try {
      if (sessionToken == null) {
        await authenticate();
      }

      final employeeData = await _getEmployeeData(name);
      debugPrint('Employee data from server: $employeeData');

      if (employeeData != null) {
        final storedPin = employeeData['pin']?.toString() ?? '';
        debugPrint('Stored PIN: $storedPin (String)');
        debugPrint('Entered PIN: $pin (String)');
        debugPrint('Comparing PINs - Stored: "$storedPin", Entered: "$pin"');

        if (storedPin == pin) {
          debugPrint('PIN match found! Proceeding with authentication...');
          // Update the cached employee data with the verified PIN
          employeeData['pin'] = pin; // Store as string
          debugPrint('Updated cached employee data with verified PIN');
          return {
            'status': 'success',
            'data': employeeData,
          };
        }
      }

      return {
        'status': 'error',
        'message': 'Invalid PIN',
      };
    } catch (e) {
      debugPrint('Error in verifyEmployeePin: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>?> _getEmployeeData(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (sessionToken != null) 'Cookie': sessionToken!,
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'hr.employee',
            'method': 'search_read',
            'args': [
              [['name', '=', name]]
            ],
            'kwargs': {
              'fields': ['id', 'name', 'pin'],
              'context': userContext ?? {
                'lang': 'en_US',
                'tz': 'Africa/Nairobi',
                'uid': 2
              }
            }
          }
        }),
      );

      debugPrint('Employee data response status: ${response.statusCode}');
      debugPrint('Employee data response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          final employee = Map<String, dynamic>.from(data['result'][0]);
          // Convert PIN to string if it exists
          if (employee['pin'] != null) {
            employee['pin'] = employee['pin'].toString();
          }
          return employee;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting employee data: $e');
      return null;
    }
  }
}
