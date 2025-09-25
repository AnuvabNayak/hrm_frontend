import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/datetime_utils.dart';

void main() {
  group('DateTimeUtils Tests', () {
    test('Parse IST DateTime formats', () {
      // Test ISO format from backend
      final result1 = DateTimeUtils.parseISTDateTime("2025-09-24T05:43:21");
      expect(result1, isNotNull);
      
      // Test space format  
      final result2 = DateTimeUtils.parseISTDateTime("2025-09-24 05:43:21");
      expect(result2, isNotNull);
      
      print("✅ Parsing tests passed");
    });
    
    test('Format IST Time', () {
      final time12 = DateTimeUtils.formatISTTime12("2025-09-24T17:30:00");
      final time24 = DateTimeUtils.formatISTTime24("2025-09-24T17:30:00");
      
      expect(time12, "5:30 PM");
      expect(time24, "17:30");
      
      print("✅ Formatting tests passed");
      print("12h: $time12, 24h: $time24");
    });
    
    test('Current Time Functions', () {
      final currentTime = DateTimeUtils.getCurrentISTTime12();
      final currentDate = DateTimeUtils.getCurrentISTDateWithDay();
      
      print("✅ Current time: $currentTime");
      print("✅ Current date: $currentDate");
    });
  });
}
