import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RoleService {
  static const _storage = FlutterSecureStorage();
  
  static Future<String?> getCurrentRole() async {
    try {
      final jwt = await _storage.read(key: 'jwt');
      if (jwt == null) return null;
      
      // Decode JWT payload (simple base64 decode, no verification needed for role check)
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      // Add padding if needed
      final normalizedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final Map<String, dynamic> claims = jsonDecode(decoded);
      
      return claims['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
  
  static Future<bool> isAdmin() async {
    final role = await getCurrentRole();
    return role == 'admin' || role == 'super_admin';
  }
  
  static Future<bool> isSuperAdmin() async {
    final role = await getCurrentRole();
    return role == 'super_admin';
  }
  
  static Future<bool> isEmployee() async {
    final role = await getCurrentRole();
    return role == 'employee';
  }
}
