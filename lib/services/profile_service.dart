import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:logging/logging.dart';
import '../models/profile_model.dart';

class ProfileService {
  // Replace with your backend API URL!
  static const String apiBase = 'http://10.0.2.2:8000/employees/me';

  static Future<ProfileModel?> fetchProfile(String jwt) async {
    try {
      final res = await http.get(
        Uri.parse(apiBase),
        headers: { 'Authorization': 'Bearer $jwt' },
      );
      
      print('Profile API Response: ${res.statusCode}');
      print('Response body: ${res.body}');
      
      if (res.statusCode == 200) {
        return ProfileModel.fromJson(jsonDecode(res.body));
      } else if (res.statusCode == 401) {
        print('Unauthorized: Invalid or expired token');
      } else if (res.statusCode == 404) {
        print('Employee profile not found');
      }
    } catch (e) {
      print('Profile fetch error: $e');
    }
    return null;
  }

  // --- PATCH: Added upload method ---
  static Future<bool> uploadProfilePicture(String jwt, String base64Image) async {
    try {
      final res = await http.put(
        Uri.parse('$apiBase/avatar'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'avatar_data': base64Image,
        }),
      );

      print('Upload response: ${res.statusCode}');
      print('Upload response body: ${res.body}');

      return res.statusCode == 200;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }
}


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/profile_model.dart';

// class ProfileService {
//   // Replace with your backend API URL!
//   static const String apiBase = 'http://10.0.2.2:8000/employees/me';

//   static Future<ProfileModel?> fetchProfile(String jwt) async {
//   try {
//     final res = await http.get(
//       Uri.parse(apiBase),
//       headers: { 'Authorization': 'Bearer $jwt' },
//     );
    
//     print('Profile API Response: ${res.statusCode}');
//     print('Response body: ${res.body}');
    
//     if (res.statusCode == 200) {
//       return ProfileModel.fromJson(jsonDecode(res.body));
//     } else if (res.statusCode == 401) {
//       print('Unauthorized: Invalid or expired token');
//     } else if (res.statusCode == 404) {
//       print('Employee profile not found');
//     }
//   } catch (e) {
//     print('Profile fetch error: $e');
//   }
//   return null;
// }
// }