import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/dashboard_widget.dart';
import '../pages/onboarding/onboarding_widget.dart';

class NavigationService {
  static Future<Widget> getInitialScreen() async {
    try {
      debugPrint('Checking initial screen...');
      final preferences = await SharedPreferences.getInstance();
      final hasSession = preferences.getString('session_token') != null;
      final hasEmployeeId = preferences.getString('employee_id') != null;
      
      debugPrint('Has session: $hasSession');
      debugPrint('Has employee ID: $hasEmployeeId');
      
      // If user has a valid session and employee ID, go to dashboard
      if (hasSession && hasEmployeeId) {
        debugPrint('Valid session found, going to dashboard');
        return const DashboardWidget();
      }
      
      // If no valid session, show onboarding
      debugPrint('No valid session, showing onboarding');
      return const OnboardingWidget();
    } catch (e, stackTrace) {
      debugPrint('Error checking session: $e');
      debugPrint('Stack trace: $stackTrace');
      // Default to onboarding if there's an error
      return const OnboardingWidget();
    }
  }
}
