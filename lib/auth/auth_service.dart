import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  final SharedPreferences _prefs;

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('https://nagaadhalls.com/web/session/authenticate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {
            'db': 'nagaadhalls',
            'login': username,
            'password': password,
          },
        }),
      );

      final data = jsonDecode(response.body);
      if (data['result'] != null) {
        String? sessionToken = response.headers['set-cookie'];
        if (sessionToken != null) {
          await _prefs.setString('session_token', sessionToken);
          await _prefs.setInt('user_id', data['result']['uid']);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Add logout and other auth methods here
}
