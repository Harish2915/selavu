import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Formats currencies safely from paise or double amounts
class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimalFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.defaultCurrencySymbol,
    decimalDigits: 2,
  );

  /// Formats paise integer to currency string (e.g., 55000 paise -> "₹550")
  static String formatPaise(int paise, {bool showDecimalsIfAny = true, String? symbol}) {
    final double rupees = paise / 100.0;
    final bool hasDecimals = paise % 100 != 0;

    String formatted;
    if (hasDecimals && showDecimalsIfAny) {
      formatted = _inrDecimalFormatter.format(rupees);
    } else {
      formatted = _inrFormatter.format(rupees);
    }

    if (symbol != null && symbol != AppConstants.defaultCurrencySymbol) {
      formatted = formatted.replaceAll(AppConstants.defaultCurrencySymbol, symbol);
    }

    return formatted;
  }

  /// Converts rupees string or double input into integer paise
  static int rupeesToPaise(dynamic amount) {
    if (amount == null) return 0;
    if (amount is int) return amount * 100;
    if (amount is double) return (amount * 100).round();
    if (amount is String) {
      final cleaned = amount.replaceAll(RegExp(r'[^\d.]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) {
        return (parsed * 100).round();
      }
    }
    return 0;
  }
}
