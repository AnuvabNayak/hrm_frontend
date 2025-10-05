// import 'dart:convert';

/// Universal DateTime utilities for Zytexa HRM
/// Handles IST timezone consistently across the entire application
class DateTimeUtils {
  // IST offset from UTC (5:30)
  // static const Duration _istOffset = Duration(hours: 5, minutes: 30);
  
  /// Parse IST datetime string from backend API
  /// Backend sends: "2025-09-24T05:43:21" (ISO format, already in IST)
  static DateTime? parseISTDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // Handle both formats: "2025-09-24T05:43:21" and "2025-09-24 05:43:21"
      final cleanStr = dateStr.replaceAll(' ', 'T');
      return DateTime.parse(cleanStr);
    } catch (e) {
      print("❌ Error parsing IST datetime: $dateStr, Error: $e");
      return null;
    }
  }
  
  /// Parse IST date string from backend
  /// Backend sends: "2025-09-24"
  static DateTime? parseISTDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      print("❌ Error parsing IST date: $dateStr, Error: $e");
      return null;
    }
  }
  
  // Display Formatters
  
  /// Format IST time as 12-hour format: "03:30 PM"
  static String formatISTTime12(String? dateStr) {
    final dt = parseISTDateTime(dateStr);
    if (dt == null) return "--:--";
    
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    final min = dt.minute.toString().padLeft(2, '0');
    return "$hour:$min $ampm";
  }
  
  /// Format IST time as 24-hour format: "15:30"
  static String formatISTTime24(String? dateStr) {
    final dt = parseISTDateTime(dateStr);
    if (dt == null) return "--:--";
    
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }
  
  /// Format IST date as DD-MM-YYYY: "24-09-2025"
  static String formatISTDate(String? dateStr) {
    final dt = parseISTDateTime(dateStr) ?? parseISTDate(dateStr);
    if (dt == null) return "--";
    
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return "$day-$month-$year";
  }
  
  /// Format complete IST datetime: "24-09-2025 03:30 PM"
  static String formatISTDateTime(String? dateStr) {
    final dt = parseISTDateTime(dateStr);
    if (dt == null) return "-- --";
    
    final date = formatISTDate(dateStr);
    final time = formatISTTime12(dateStr);
    return "$date $time";
  }
  
  // Current Time Helpers (for display, not API calls)
  
  /// Get current IST time as 12-hour string: "03:30 PM"
  static String getCurrentISTTime12() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? "PM" : "AM";
    final min = now.minute.toString().padLeft(2, '0');
    return "$hour:$min $ampm";
  }
  
  /// Get current IST time as 24-hour string: "15:30"
  static String getCurrentISTTime24() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }
  
  /// Get current IST date: "24-09-2025"
  static String getCurrentISTDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    return "$day-$month-$year";
  }
  
  /// Get current IST date with day name: "24-09-2025, Wednesday"
  static String getCurrentISTDateWithDay() {
    final now = DateTime.now();
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    final dayName = dayNames[now.weekday - 1];
    return "${getCurrentISTDate()}, $dayName";
  }
  
  // Validation & Utility
  
  /// Check if a datetime string represents today in IST
  static bool isToday(String? dateStr) {
    final dt = parseISTDateTime(dateStr) ?? parseISTDate(dateStr);
    if (dt == null) return false;
    
    final now = DateTime.now();
    return dt.day == now.day && dt.month == now.month && dt.year == now.year;
  }
  
  /// Get duration between two IST datetime strings
  static Duration? getDuration(String? startDateStr, String? endDateStr) {
    final start = parseISTDateTime(startDateStr);
    final end = parseISTDateTime(endDateStr);
    
    if (start == null || end == null) return null;
    return end.difference(start);
  }
  
  /// Format duration as HH:MM:SS
  static String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }
  
  /// Debug helper - shows parsing details
  static Map<String, String> debugDateTime(String? dateStr) {
    final dt = parseISTDateTime(dateStr);
    if (dt == null) {
      return {"error": "Failed to parse: $dateStr"};
    }
    
    return {
      "input": dateStr ?? "null",
      "parsed": dt.toString(),
      "formatted_12h": formatISTTime12(dateStr),
      "formatted_24h": formatISTTime24(dateStr),
      "formatted_date": formatISTDate(dateStr),
      "is_today": isToday(dateStr).toString(),
    };
  }
  static String formatISTDateFromDateTime(DateTime? dt) {
    if (dt == null) return "--";
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return "$d-$m-$y";
  }

  static String formatDisplayDate(DateTime? dt) {
    if (dt == null) return "--";
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dn = days[dt.weekday - 1];
    final mn = months[dt.month - 1];
    return "$dn, ${dt.day} $mn";
  }

  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Formats a backend date or datetime string into "DD-MM-YYYY, Wed"
  static String formatISTDateWithDay(String? dateStr) {
    final dt = parseISTDateTime(dateStr) ?? parseISTDate(dateStr);
    if (dt == null) return "--";
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dn = days[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return "$d-$m-$y, $dn";
  }
}
