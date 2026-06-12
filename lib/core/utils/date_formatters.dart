import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static final DateFormat _dateTime = DateFormat('MMM d, yyyy - h:mm a');
  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String shortDate(DateTime value) => _shortDate.format(value);

  static String relativeExpiry(DateTime expiryDate) {
    final difference = expiryDate.difference(DateTime.now());
    if (difference.isNegative) {
      return 'Expired';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min left';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr left';
    }
    return '${difference.inDays} days left';
  }
}
