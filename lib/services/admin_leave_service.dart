import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_leave_models.dart';

class AdminLeaveService {
  static const String _base = 'http://10.0.2.2:8000';
  static const _storage = FlutterSecureStorage();

  static Future<String?> _token() => _storage.read(key: 'jwt');

  static Future<List<AdminLeaveRequest>?> fetchAllLeaveRequests({int skip = 0, int limit = 50}) async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/leaves/?skip=$skip&limit=$limit'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        
        // Get employee names for each request
        List<AdminLeaveRequest> requests = [];
        for (var item in data) {
          final employeeName = await _getEmployeeName(item['employee_id']);
          requests.add(AdminLeaveRequest.fromJson({
            ...item,
            'employee_name': employeeName?['name'],
            'emp_code': employeeName?['emp_code'],
          }));
        }
        return requests;
      }
    } catch (e) {
      print('Error fetching leave requests: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _getEmployeeName(int employeeId) async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/employees/$employeeId'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'name': data['name'],
          'emp_code': data['emp_code'],
        };
      }
    } catch (e) {
      print('Error fetching employee name: $e');
    }
    return null;
  }

  static Future<String?> approveLeaveRequest(int leaveId) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/leaves/$leaveId/approve'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(res.body);
        return data['detail'] ?? 'Failed to approve leave request';
      }
    } catch (e) {
      return 'Network error';
    }
  }

  static Future<String?> denyLeaveRequest(int leaveId) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/leaves/$leaveId/deny'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(res.body);
        return data['detail'] ?? 'Failed to deny leave request';
      }
    } catch (e) {
      return 'Network error';
    }
  }

  static Future<List<EmployeeBasic>?> fetchAllEmployees() async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/employees/?limit=100'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => EmployeeBasic.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
    return null;
  }
}
