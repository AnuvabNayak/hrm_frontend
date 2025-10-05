import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_employee_models.dart';

class AdminEmployeeService {
  static const String _base = 'http://10.0.2.2:8000';
  static const _storage = FlutterSecureStorage();

  static Future<String?> _token() => _storage.read(key: 'jwt');

  static Future<String?> createUserAndEmployee(CreateEmployeeRequest request) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/admin/create-user-employee'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
      
      if (res.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(res.body);
        return data['detail'] ?? 'Failed to create employee';
      }
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }

  static Future<List<AdminEmployee>?> fetchAllEmployees() async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/employees/?limit=100'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => AdminEmployee.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
    return null;
  }

  static Future<AdminEmployee?> fetchEmployee(int employeeId) async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/employees/$employeeId'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        return AdminEmployee.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('Error fetching employee: $e');
    }
    return null;
  }

  static Future<String?> updateEmployee(int employeeId, UpdateEmployeeRequest request) async {
    try {
      final jwt = await _token();
      final res = await http.put(
        Uri.parse('$_base/employees/$employeeId'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
      
      if (res.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(res.body);
        return data['detail'] ?? 'Failed to update employee';
      }
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }

  static Future<String?> deleteEmployee(int employeeId) async {
    try {
      final jwt = await _token();
      final res = await http.delete(
        Uri.parse('$_base/employees/$employeeId'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(res.body);
        return data['detail'] ?? 'Failed to delete employee';
      }
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }
}
