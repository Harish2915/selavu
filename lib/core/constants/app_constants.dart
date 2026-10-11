/// Central Application Constants for Selavu
class AppConstants {
  static const String appName = 'Selavu';
  static const String appTagline = 'Track Trips, Split Fairly, Settle Easily';
  static const String appMeaning = 'Expense / Spending';

  // Currency
  static const String defaultCurrencySymbol = '₹';
  static const String defaultCurrencyCode = 'INR';

  // Security keys
  static const String keyAppPin = 'selavu_app_pin';
  static const String keyBiometricEnabled = 'selavu_biometric_enabled';
  static const String keySecurityType = 'selavu_security_type'; // 'biometric', 'pin', 'none'
  static const String keyIsFirstLaunch = 'selavu_first_launch_done';
  static const String keyThemeMode = 'selavu_theme_mode'; // 'system', 'light', 'dark'
  static const String keyCurrencySymbol = 'selavu_currency_symbol';
  static const String keyCurrencyCode = 'selavu_currency_code';

  // Supabase Table names
  static const String tableProfiles = 'profiles';
  static const String tableTrips = 'trips';
  static const String tableTripMembers = 'trip_members';
  static const String tableCategories = 'categories';
  static const String tableExpenses = 'expenses';
  static const String tableExpenseShares = 'expense_shares';
  static const String tablePayments = 'payments';

  // Default Categories
  static const List<Map<String, String>> defaultCategories = [
    {'name': 'Hotel', 'icon': 'hotel', 'color': '#FF7A00'},
    {'name': 'Food', 'icon': 'food', 'color': '#FC8019'},
    {'name': 'Bus', 'icon': 'bus', 'color': '#FF9F43'},
    {'name': 'Train', 'icon': 'train', 'color': '#54A0FF'},
    {'name': 'Auto', 'icon': 'auto', 'color': '#10AC84'},
    {'name': 'Cab', 'icon': 'cab', 'color': '#EE5253'},
    {'name': 'Fuel', 'icon': 'fuel', 'color': '#FF6B6B'},
    {'name': 'Tickets', 'icon': 'tickets', 'color': '#48DBFB'},
    {'name': 'Temple', 'icon': 'temple', 'color': '#FFA502'},
    {'name': 'Shopping', 'icon': 'shopping', 'color': '#9B59B6'},
    {'name': 'Snacks', 'icon': 'snacks', 'color': '#E67E22'},
    {'name': 'Other', 'icon': 'other', 'color': '#7F8C8D'},
  ];
}
