import 'package:intl/intl.dart';

class Fmt {
  static String money(double amount, {String currency = 'CLP'}) {
    if (currency == 'CLP') {
      final n = NumberFormat('#,###', 'es_CL');
      return '\$${n.format(amount.round())}';
    }
    return NumberFormat.currency(locale: 'es_CL', symbol: '\$').format(amount);
  }

  static String moneyCompact(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    }
    return money(amount);
  }

  static String month(DateTime d) =>
      DateFormat('MMMM yyyy', 'es').format(d);

  static String monthCap(DateTime d) {
    final s = month(d);
    return s[0].toUpperCase() + s.substring(1);
  }

  static String monthShort(DateTime d) =>
      DateFormat('MMM', 'es').format(d);

  static String dayMonth(DateTime d) =>
      DateFormat('d MMM', 'es').format(d);

  static String weekdayShort(DateTime d) =>
      DateFormat('EEE', 'es').format(d);

  static String fullDate(DateTime d) =>
      DateFormat("d 'de' MMMM", 'es').format(d);

  static String percent(double v) =>
      '${(v * 100).toStringAsFixed(0)}%';
}
