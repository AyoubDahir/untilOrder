class SessionManager {
  static const String KEY_SESSION_TOKEN = 'session_token';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_EMPLOYEE_ID = 'employee_id';
  static const String KEY_EMPLOYEE_NAME = 'employee_name';
  static const String KEY_CASHIER_PIN = 'cashier_pin';

  final SharedPreferences _prefs;

  bool get isLoggedIn {
    final sessionToken = _prefs.getString(KEY_SESSION_TOKEN);
    return sessionToken != null;
  }

  bool get isCashierAuthenticated {
    final cashierPin = _prefs.getString(KEY_CASHIER_PIN);
    return cashierPin != null;
  }

  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(KEY_SESSION_TOKEN),
      _prefs.remove(KEY_USER_ID),
      _prefs.remove(KEY_EMPLOYEE_ID),
      _prefs.remove(KEY_EMPLOYEE_NAME),
      // Don't clear cashier PIN unless explicitly requested
      // _prefs.remove(KEY_CASHIER_PIN),
    ]);
  }
}
