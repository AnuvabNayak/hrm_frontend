import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_attendance_models.dart';

class AdminAttendanceService {
  static const String _base = 'http://10.0.2.2:8000';
  static const _storage = FlutterSecureStorage();

  static Future<String?> _token() => _storage.read(key: 'jwt');

  static Future<List<EmployeeAttendanceStatus>?> fetchAllEmployeesStatus() async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/attendance-rt/admin/all-employees-status'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => EmployeeAttendanceStatus.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching all employees status: $e');
    }
    return null;
  }

  static Future<List<EmployeeAttendanceHistory>?> fetchEmployeeHistory(int employeeId, {int days = 14}) async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/attendance-rt/admin/employee/$employeeId/recent?days=$days'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => EmployeeAttendanceHistory.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching employee history: $e');
    }
    return null;
  }

  static Future<String?> clockInEmployee(int employeeId) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/attendance-rt/admin/employee/$employeeId/clock-in'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(res.body);
        return data['detail'] ?? 'Failed to clock in employee';
      }
    } catch (e) {
      return 'Network error';
    }
  }

  static Future<String?> clockOutEmployee(int employeeId) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/attendance-rt/admin/employee/$employeeId/clock-out'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(res.body);
        return data['detail'] ?? 'Failed to clock out employee';
      }
    } catch (e) {
      return 'Network error';
    }
  }
}
