import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginResult {
  final bool success;
  final String? sessionToken;
  final int? userId;
  final String? employeeId;
  final String? employeeName;
  final String? errorMessage;

  LoginResult({
    required this.success,
    this.sessionToken,
    this.userId,
    this.employeeId,
    this.employeeName,
    this.errorMessage,
  });
}

class AuthService {
  static const String baseUrl = 'https://nagaadhalls.com/web';

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    try {
      debugPrint('Starting admin authentication...');
      
      // First authenticate with admin credentials
      final response = await http.post(
        Uri.parse('$baseUrl/session/authenticate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'db': 'postgres',
            'login': 'admin',
            'password': '2025',
          }
        }),
      );

      debugPrint('Admin auth response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        return LoginResult(
          success: false,
          errorMessage: 'Server error: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        debugPrint('Admin auth error: ${data['error']}');
        return LoginResult(
          success: false,
          errorMessage: data['error']['data']['message'] ?? 'Admin authentication failed',
        );
      }

      if (data['result'] == null) {
        return LoginResult(
          success: false,
          errorMessage: 'Invalid admin credentials',
        );
      }

      final sessionToken = response.headers['set-cookie'];
      final uid = data['result']['uid'];
      debugPrint('Got session token: $sessionToken');
      debugPrint('Got admin user ID: $uid');

      // Return successful login with the employee information
      return LoginResult(
        success: true,
        sessionToken: sessionToken,
        userId: uid,
        employeeId: username,  // Using the employee ID/username passed in
        employeeName: username, // Using the same as employee ID for now
      );
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      return LoginResult(
        success: false,
        errorMessage: 'Authentication failed: $e',
      );
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('Starting logout process...');
      final response = await http.post(
        Uri.parse('$baseUrl/session/destroy'),
        headers: {'Content-Type': 'application/json'},
      );
      debugPrint('Logout response status: ${response.statusCode}');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      debugPrint('Checking authentication status...');
      final response = await http.get(
        Uri.parse('$baseUrl/session/get_session_info'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Session check response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Session info: ${response.body}');
        return data['result'] != null && data['result']['uid'] != null;
      }
    } catch (e) {
      debugPrint('Session check error: $e');
    }
    return false;
  }
}
