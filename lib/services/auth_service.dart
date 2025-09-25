import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> login({
    required String username,
    required String password,
  }) async {
    // Use /token endpoint!
    const String apiUrl = "http://10.0.2.2:8000/token"; // Or your actual backend
    
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "username": username,
        "password": password,
      },
      // No jsonEncode here!
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      if (token != null) {
        await _storage.write(key: "jwt", value: token);
        return null;
      }
      return "Invalid response from server.";
    } else if (response.statusCode == 401) {
      return "Incorrect username or password.";
    } else {
      return "Login failed; try again later.";
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: "jwt");
  }
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _storage.delete(key: "jwt");
    // await _storage.delete(key: "jwt");
    // await prefs.remove('access_token');
    // await prefs.remove('access_token');
    await prefs.remove('access_token');
    await prefs.remove('user_role');
  }
}
