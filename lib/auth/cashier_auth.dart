Future<bool> authenticateCashier(String pin) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('cashier_pin');

    if (storedPin == null) {
      // First time setup - store the PIN
      await prefs.setString('cashier_pin', pin);
      return true;
    }

    // Verify PIN
    return storedPin == pin;
  } catch (e) {
    debugPrint('Cashier authentication error: $e');
    return false;
  }
}
