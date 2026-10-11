import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _tripDateRange = DateFormat('dd MMM');
  static final DateFormat _fullDate = DateFormat('dd MMM yyyy');
  static final DateFormat _expenseGroup = DateFormat('EEEE, dd MMMM');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String formatTripRange(DateTime from, DateTime? to) {
    if (to == null) {
      return '${_tripDateRange.format(from)} - Ongoing';
    }
    if (from.year == to.year) {
      return '${_tripDateRange.format(from)} – ${_tripDateRange.format(to)} ${to.year}';
    }
    return '${_fullDate.format(from)} – ${_fullDate.format(to)}';
  }

  static String formatFullDate(DateTime date) {
    return _fullDate.format(date);
  }

  static String formatExpenseDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today, ${_tripDateRange.format(date)}';
    } else if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_tripDateRange.format(date)}';
    }
    return _expenseGroup.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }
}
