import 'package:intl/intl.dart';

/// 📅 Date Formatter - Aplikasi Monitoring Kompos
/// Helper functions untuk format tanggal dan waktu

class DateFormatter {
  DateFormatter._();

  // ==================== DATE FORMATS ====================
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat _fullDateTimeFormat = DateFormat('EEEE, dd MMMM yyyy HH:mm');

  // ==================== FORMAT FUNCTIONS ====================
  /// Format date only (e.g., "16 Mar 2026")
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  /// Format time only (e.g., "14:30")
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Format date and time (e.g., "16 Mar 2026, 14:30")
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Format full date and time (e.g., "Sabtu, 16 Maret 2026 14:30")
  static String formatFullDateTime(DateTime dateTime) {
    return _fullDateTimeFormat.format(dateTime);
  }

  /// Format date from ISO string
  static String formatDateFromString(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return formatDate(dateTime);
    } catch (e) {
      return isoString;
    }
  }

  /// Format datetime from ISO string
  static String formatDateTimeFromString(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return formatDateTime(dateTime);
    } catch (e) {
      return isoString;
    }
  }

  // ==================== RELATIVE TIME ====================
  /// Format relative time (e.g., "5 menit lalu", "2 jam lalu")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    }
  }

  /// Format relative time from ISO string
  static String formatRelativeTimeFromString(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return formatRelativeTime(dateTime);
    } catch (e) {
      return isoString;
    }
  }

  // ==================== CUSTOM FORMATS ====================
  /// Format for history log (e.g., "16 Mar 2026, 10:30:25")
  static String formatForLog(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm:ss').format(dateTime);
  }

  /// Format for chart labels (e.g., "14:30", "16 Mar")
  static String formatForChart(DateTime dateTime, {bool showDate = false}) {
    if (showDate) {
      return DateFormat('dd MMM').format(dateTime);
    }
    return formatTime(dateTime);
  }
}
