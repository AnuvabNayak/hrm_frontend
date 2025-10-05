import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/leave_models.dart';

class LeaveService {
  static const String _base = 'http://10.0.2.2:8000';
  static const _storage = FlutterSecureStorage();

  static Future<String?> _token() => _storage.read(key: 'jwt');
  static bool _isUnauthorized(http.Response r) => r.statusCode == 401;

  static Future<List<LeaveRequest>?> fetchLeaveRequests() async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/leaves/'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      if (_isUnauthorized(res)) {
        return null;
      }
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => LeaveRequest.fromJson(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<LeaveBalance?> fetchLeaveBalance() async {
    try {
      final jwt = await _token();
      final res = await http.get(
        Uri.parse('$_base/leave-balance/me'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      if (res.statusCode == 200) {
        return LeaveBalance.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> createLeaveRequest(LeaveRequestCreate payload) async {
    try {
      final jwt = await _token();
      final res = await http.post(
        Uri.parse('$_base/leaves/'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload.toJson()),
      );
      if (res.statusCode == 201) return null;
      if (res.statusCode == 400 || res.statusCode == 422) {
        final data = jsonDecode(res.body);
        return data['detail']?.toString() ?? 'Invalid data';
      }
      if (res.statusCode == 401) return 'Unauthorized. Please login again.';
      return 'Failed to create leave request';
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }
}
