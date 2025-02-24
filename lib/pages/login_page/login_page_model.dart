import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nguat/pages/menu_page/menu_page_model.dart';
import 'package:nguat/dashboard/dashboard_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class LoginPageModel with ChangeNotifier {
  final MenuPageModel menuPageModel;
  List<Map<String, dynamic>> cashiers = [];
  late Map<String, dynamic> selectedEmployee = {};
  bool _isLoadingCashiers = false;
  bool get isLoadingCashiers => _isLoadingCashiers;
  bool _disposed = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  bool isPasswordVisible = false;
  String? errorMessage;
  bool isLoggingIn = false;
  bool get isLoading => _isLoadingCashiers || isLoggingIn;
  String? _sessionToken;
  String? _employeeId;
  String? _employeeName;
  int? _userId;
  BuildContext? _context; // Make context optional and private
  SharedPreferences? _prefs;

  LoginPageModel({required this.menuPageModel}) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    if (_prefs == null) return;

    try {
      _sessionToken = _prefs!.getString('session_token');
      _employeeId = _prefs!.getString('employee_id');
      _employeeName = _prefs!.getString('employee_name');

      // Handle userId as string
      final savedUserId = _prefs!.getString('user_id');
      if (savedUserId != null && savedUserId.isNotEmpty) {
        _userId = int.tryParse(savedUserId);
      }

      final savedSelectedEmployee = _prefs!.getString('selectedEmployee');
      if (savedSelectedEmployee != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(savedSelectedEmployee);
          // Ensure ID is stored as string
          if (decoded['id'] != null) {
            decoded['id'] = decoded['id'].toString();
          }
          // Ensure PIN is stored as string
          if (decoded['pin'] != null) {
            decoded['pin'] = decoded['pin'].toString();
          }
          selectedEmployee = decoded;
        } catch (e) {
          debugPrint('Error loading saved employee: $e');
        }
      }

      final savedCashiers = _prefs!.getString('cashiersList');
      if (savedCashiers != null) {
        try {
          final List<dynamic> decodedCashiers = json.decode(savedCashiers);
          cashiers = decodedCashiers.map((cashier) {
            final Map<String, dynamic> c = Map<String, dynamic>.from(cashier);
            // Ensure ID and PIN are stored as strings
            if (c['id'] != null) c['id'] = c['id'].toString();
            if (c['pin'] != null) c['pin'] = c['pin'].toString();
            return c;
          }).toList();
        } catch (e) {
          debugPrint('Error loading cached cashiers: $e');
        }
      }

      debugPrint('Loaded login state successfully');
    } catch (e) {
      debugPrint('Error loading login state: $e');
      rethrow;
    }
  }

  Future<void> saveLoginData({
    required String sessionToken,
    required int userId,
    required String employeeId,
    required String employeeName,
  }) async {
    if (_prefs == null) return;

    await _prefs!.setString('session_token', sessionToken);
    await _prefs!.setString('user_id', userId.toString()); // Store as string
    await _prefs!.setString('employee_id', employeeId);
    await _prefs!.setString('employee_name', employeeName);

    _sessionToken = sessionToken;
    _userId = userId;
    _employeeId = employeeId;
    _employeeName = employeeName;
  }

  Future<void> _saveLoginData() async {
    if (_prefs == null) return;

    await _prefs!.setString('session_token', _sessionToken ?? '');
    await _prefs!.setString('user_id', _userId?.toString() ?? ''); // Store as string
    await _prefs!.setString('employee_id', _employeeId ?? '');
    await _prefs!.setString('employee_name', _employeeName ?? '');
    if (selectedEmployee.isNotEmpty) {
      await _prefs!.setString('selectedEmployee', json.encode(selectedEmployee));
    }
    // Save cashiers list
    if (cashiers.isNotEmpty) {
      await _prefs!.setString('cashiersList', json.encode(cashiers));
    }
  }

  Future<void> clearLoginData() async {
    if (_prefs == null) return;

    debugPrint('Clearing login data...');
    
    try {
      // First, destroy the session on the server
      final authService = AuthService();
      await authService.logout();
      
      // Clear all session-related data
      await _prefs!.remove('session_token');
      await _prefs!.remove('user_id');
      await _prefs!.remove('employee_id');
      await _prefs!.remove('employee_name');
      await _prefs!.remove('selectedEmployee');
      await _prefs!.remove('cashier_pin');
      await _prefs!.remove('cashiersList');

      // Reset all state variables
      _sessionToken = null;
      _employeeId = null;
      _employeeName = null;
      _userId = null;
      selectedEmployee = {};
      errorMessage = null;
      cashiers = [];
      
      // Clear text fields
      usernameController.clear();
      passwordController.clear();

      debugPrint('Login data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing login data: $e');
    }
    
    notifyListeners();
  }

  Future<void> clearCashierData() async {
    if (_prefs == null) return;

    await _prefs!.remove('cashiersList');
    cashiers = [];
    notifyListeners();
  }

  Future<void> fetchCashiers() async {
    if (_disposed) return;

    try {
      _isLoadingCashiers = true;
      cashiers = []; // Clear existing cashiers
      errorMessage = null;
      if (!_disposed) notifyListeners();

      debugPrint('Starting cashier fetch process...');

      // First authenticate to get session token
      const username = 'admin';
      const password = '2025';
      const url = 'https://nagaadhalls.com/web/session/authenticate';

      // Clear any existing session token before new authentication
      _sessionToken = null;

      final authBody = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'db': 'postgres',
          'login': username,
          'password': password,
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(authBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['result'] != null) {
          // Get the new session token
          _sessionToken = response.headers['set-cookie'];
          debugPrint('New session token obtained: $_sessionToken');

          // Now fetch cashiers with new session
          final cashiersResponse = await _fetchCashiersList();
          if (cashiersResponse != null) {
            cashiers = cashiersResponse;
            // Cache the fetched cashiers
            if (_prefs != null) {
              await _prefs!.setString('cashiersList', json.encode(cashiers));
            }
            debugPrint('Cashiers fetched and cached successfully');
          }
        } else {
          errorMessage = 'Authentication failed';
          debugPrint('Authentication failed: $responseData');
        }
      } else {
        errorMessage = 'Server error: ${response.statusCode}';
        debugPrint('Server error during authentication: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      debugPrint('Error during fetchCashiers: $e');
    } finally {
      _isLoadingCashiers = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchCashiersList() async {
    try {
      const employeeUrl = 'https://nagaadhalls.com/web/dataset/call_kw';
      debugPrint('Fetching employees from: $employeeUrl');

      final employeeBody = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'hr.employee',
          'method': 'search_read',
          'args': [
            [
              ['active', '=', true],
              ['pin', '!=', null],
              ['id', '!=', null]
            ]
          ],
          'kwargs': {
            'fields': ['id', 'name', 'pin'],
          },
        },
      };
      debugPrint('Employee request body: ${jsonEncode(employeeBody)}');

      final employeeResponse = await http.post(
        Uri.parse(employeeUrl),
        headers: _headers,
        body: jsonEncode(employeeBody),
      );

      debugPrint('Employee response status: ${employeeResponse.statusCode}');
      debugPrint('Employee response headers: ${employeeResponse.headers}');
      debugPrint('Employee response body: ${employeeResponse.body}');

      if (employeeResponse.statusCode != 200) {
        errorMessage = 'Failed to fetch employees: ${employeeResponse.statusCode}';
        debugPrint(errorMessage);
        return null;
      }

      final employeeData = jsonDecode(employeeResponse.body);

      if (!employeeData.containsKey('result')) {
        errorMessage = 'Invalid employee data response';
        debugPrint('Employee data: $employeeData');
        return null;
      }

      if (employeeData['result'] == null ||
          (employeeData['result'] is List && employeeData['result'].isEmpty)) {
        errorMessage = 'No employees found';
        debugPrint('Employee result: ${employeeData['result']}');
        return null;
      }

      final employees = employeeData['result'] as List;
      // if (employees.isEmpty) {
      //   errorMessage = 'No cashiers available';
      //   debugPrint(errorMessage);
      //   return null;
      // }

      // Keep all employee data including PIN
      final filteredEmployees = employees
          .where((employee) =>
              employee['id'] != null &&
              employee['name'] != null &&
              employee['name'].toString().isNotEmpty)
          .map((employee) => {
                'id': employee['id'],
                'name': employee['name'],
                'pin': employee['pin']?.toString() ?? '',
              })
          .toList();

      if (filteredEmployees.isEmpty) {
        errorMessage = 'No valid cashiers found';
        debugPrint(errorMessage);
        return null;
      }

      //debugPrint('Cashiers fetched successfully: ${filteredEmployees.length}');
      for (var cashier in filteredEmployees) {
       // debugPrint('Cashier: ${cashier['name']}');
      }

      return filteredEmployees;
    } catch (e, stackTrace) {
      if (e is SocketException) {
        errorMessage = 'Network error: Please check your internet connection';
      } else if (e is TimeoutException) {
        errorMessage = 'Request timed out: Server is not responding';
      } else {
        errorMessage = 'Error loading cashiers: ${e.toString()}';
      }
      debugPrint('Error fetching cashiers: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  void setSelectedEmployee(Map<String, dynamic>? employee) {
    debugPrint('Setting selected employee: $employee');
    if (employee != null) {
      // Make a deep copy and ensure ID and PIN are strings
      final Map<String, dynamic> copy = Map<String, dynamic>.from(employee);
      if (copy['id'] != null) copy['id'] = copy['id'].toString();
      if (copy['pin'] != null) copy['pin'] = copy['pin'].toString();
      selectedEmployee = copy;
      usernameController.text = copy['name'] ?? '';
      debugPrint('Stored employee data: $selectedEmployee');
    } else {
      selectedEmployee = {};
      usernameController.text = '';
    }
    notifyListeners();
  }

  Future<bool> verifyCashierPin(String pin) async {
    try {
      debugPrint('Starting PIN verification...');
      debugPrint('Selected employee: ${selectedEmployee['name']} (ID: ${selectedEmployee['id']})');
      debugPrint('Entered PIN: $pin');

      // First authenticate with admin credentials to get a fresh session
      const username = 'admin';
      const password = '2025';
      const url = 'https://nagaadhalls.com/web/session/authenticate';

      final authResponse = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'db': 'postgres',
            'login': username,
            'password': password,
          },
        }),
      );

      if (authResponse.statusCode != 200) {
        debugPrint('Authentication failed: ${authResponse.statusCode}');
        return false;
      }

      final authData = json.decode(authResponse.body);
      if (authData['error'] != null) {
        debugPrint('Authentication error: ${authData['error']}');
        return false;
      }

      _sessionToken = authResponse.headers['set-cookie'];
      debugPrint('Got new session token: $_sessionToken');

      // Now verify the employee PIN with the fresh session
      final employeeResponse = await http.post(
        Uri.parse('https://nagaadhalls.com/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _sessionToken ?? '',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'hr.employee',
            'method': 'search_read',
            'args': [[['id', '=', selectedEmployee['id']]]],
            'kwargs': {
              'fields': ['id', 'name', 'pin'],
            },
          },
        }),
      );

      debugPrint('Employee data response status: ${employeeResponse.statusCode}');
      debugPrint('Employee data response: ${employeeResponse.body}');

      if (employeeResponse.statusCode == 200) {
        final employeeData = json.decode(employeeResponse.body);
        if (employeeData['result'] != null && employeeData['result'].isNotEmpty) {
          final employee = employeeData['result'][0];
          final storedPin = employee['pin'];
          debugPrint('Employee data from server: $employee');
          debugPrint('Stored PIN: $storedPin (${storedPin.runtimeType})');
          debugPrint('Entered PIN: $pin (${pin.runtimeType})');

          // Convert both PINs to strings and trim any whitespace
          final storedPinStr = storedPin?.toString().trim() ?? '';
          final enteredPinStr = pin.trim();
          
          debugPrint('Comparing PINs - Stored: "$storedPinStr", Entered: "$enteredPinStr"');

          if (storedPinStr.isNotEmpty && storedPinStr == enteredPinStr) {
            debugPrint('PIN match found! Proceeding with authentication...');
            
            // Update the cached employee data with the verified PIN
            selectedEmployee['pin'] = storedPinStr;
            debugPrint('Updated cached employee data with verified PIN');

            // Save employee data
            await _prefs?.setString('session_token', _sessionToken!);
            await _prefs?.setString('user_id', authData['result']['uid'].toString());
            await _prefs?.setString('employee_id', selectedEmployee['id'].toString());
            await _prefs?.setString('employee_name', selectedEmployee['name'].toString());
            await _prefs?.setString('selectedEmployee', json.encode(selectedEmployee));

            // Update menu page model
            menuPageModel.sessionToken = _sessionToken;
            menuPageModel.employeeId = selectedEmployee['id'].toString();
            menuPageModel.employeeName = selectedEmployee['name'].toString();
            menuPageModel.userId = authData['result']['uid'].toString();

            return true;
          }
        }
      }

      debugPrint('PIN verification failed');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Error during PIN verification: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> login() async {
    if (_context == null) {
      debugPrint('Error: Context is null');
      return false;
    }

    final username = usernameController.text.trim();
    final pin = passwordController.text.trim();

    debugPrint('Attempting login with Username: $username, PIN: $pin');

    if (username.isEmpty || pin.isEmpty) {
      errorMessage = 'Please enter both username and password';
      notifyListeners();
      return false;
    }

    try {
      isLoggingIn = true;
      errorMessage = null;
      notifyListeners();

      // First verify if the employee exists with the given username and PIN
      bool employeeFound = false;
      Map<String, dynamic>? matchingEmployee;

      debugPrint('Searching for employee in cached list...');
      debugPrint('Number of cached employees: ${cashiers.length}');
      
      for (var employee in cashiers) {
        debugPrint('Checking employee: ${employee['name']} with PIN: ${employee['pin']}');
        if (employee['name'].toString() == username && 
            employee['pin'].toString() == pin) {
          employeeFound = true;
          matchingEmployee = employee;
          debugPrint('Found matching employee: $matchingEmployee');
          break;
        }
      }

      if (!employeeFound || matchingEmployee == null) {
        debugPrint('No employee found with matching username and PIN');
        errorMessage = 'Invalid username or PIN';
        isLoggingIn = false;
        notifyListeners();
        return false;
      }

      // Set the selected employee
      setSelectedEmployee(matchingEmployee);

      // Verify PIN and get session token
      final success = await verifyCashierPin(pin);
      if (!success) {
        errorMessage = 'Authentication failed';
        isLoggingIn = false;
        notifyListeners();
        return false;
      }

      // Navigate to dashboard on success
      if (_context != null && _context!.mounted) {
        Navigator.pushAndRemoveUntil(
          _context!,
          MaterialPageRoute(
            builder: (context) => DashboardWidget(),
          ),
          (route) => false,
        );
      }

      isLoggingIn = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      errorMessage = 'Login failed: ${e.toString()}';
      isLoggingIn = false;
      notifyListeners();
      return false;
    }
  }

  void checkLoginState() async {
    if (_sessionToken != null && _userId != null) {
      // Verify if the session is still valid
      final authService = AuthService();
      final isValid = await authService.isAuthenticated();
      
      if (isValid) {
        if (_context != null && _context!.mounted) {
          Navigator.pushReplacementNamed(_context!, '/dashboard');
        }
      } else {
        // If session is invalid, clear all data
        await clearLoginData();
      }
    }
  }

  // Helper method to get headers with session token
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_sessionToken != null) {
      headers['Cookie'] = _sessionToken!;
    }

    return headers;
  }

  @override
  void dispose() {
    _disposed = true;
    usernameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  //getters
  String? get selectedCashierId => selectedEmployee['id']?.toString();
  String? get selectedCashier => selectedEmployee['name'] as String?;
  String? get sessionToken => _sessionToken;
  String? get employeeName => _employeeName;
  String? get employeeId => _employeeId;
  int? get userId => _userId;

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }
}
