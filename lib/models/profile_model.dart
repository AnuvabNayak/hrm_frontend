class ProfileModel {
  final int? employeeId;
  final String? name;
  final String? username;
  final String? phone;
  final String? email;
  final String? empCode;
  final String? avatarUrl;

  const ProfileModel({
    this.employeeId,
    this.name,
    this.username,
    this.phone,
    this.email,
    this.empCode,
    this.avatarUrl,
  });

  // Helper to sanitize "string" and empty values to null
  static String? _clean(String? v) {
    if (v == null) return null;
    final trimmed = v.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase() == 'string') return null;
    return trimmed;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      employeeId: json['id'] ?? json['employee_id'],
      name: _clean(json['name'] as String?),
      username: _clean(json['username'] as String?),
      phone: _clean(json['phone'] as String?),
      email: _clean(json['email'] as String?),
      empCode: _clean(json['emp_code'] as String?),
      avatarUrl: _clean(json['avatar_url'] as String?),
    );
  }

  // Display getters
  String get displayPhone => (phone != null && phone!.isNotEmpty) ? phone! : 'Not available';
  String get displayEmail => (email != null && email!.isNotEmpty) ? email! : 'Not available';
  String get displayEmpCode => (empCode != null && empCode!.isNotEmpty) ? empCode! : 'Not available';

  // Convenient composite display name for UI
  String get displayName {
    final parts = <String>[];
    if (empCode != null && empCode!.trim().isNotEmpty && empCode!.toLowerCase() != 'string') {
      parts.add(empCode!.trim());
    }
    if (name != null && name!.trim().isNotEmpty && name!.toLowerCase() != 'string') {
      parts.add(name!.trim());
    } else if (username != null && username!.trim().isNotEmpty && username!.toLowerCase() != 'string') {
      parts.add(username!.trim());
    }
    if (parts.isEmpty) return 'Employee';
    return parts.join(' · ');
  }
}


// class ProfileModel {
//   final String name;
//   final int employeeId;
//   final String? email;
//   final String? phone;
//   final String? avatarUrl;
//   final String? empCode;
//   final String? username;
//   // Add more fields if backend returns them

//   ProfileModel({
//     required this.name,
//     required this.employeeId,
//     this.email,
//     this.phone,
//     this.avatarUrl,
//     this.empCode,
//     this.username,
//   });

//   // String get displayPhone => (phone != null && phone!.isNotEmpty) ? phone! : 'Not available';
//   // String get displayEmail => (email != null && email!.isNotEmpty) ? email! : 'Not available';
//   // String get displayEmpCode => (empCode != null && empCode!.isNotEmpty) ? empCode! : 'Not available';

//   static String? _clean(String? v) {
//     if (v == null) return null;
//     final trimmed = v.trim();
//     if (trimmed.isEmpty) return null;
//     if (trimmed.toLowerCase() == 'string') return null;
//     return trimmed;
//   }
    
//   factory ProfileModel.fromJson(Map<String, dynamic> json) {
//     return ProfileModel(
//       name: json['name'] ?? '-',
//       employeeId: json['id'] ?? 0,
//       email: json['email'],
//       phone: json['phone'],
//       avatarUrl: json['avatar_url'],
//       empCode: json['emp_code'],
//       username: json['username'],
//     );
//   }
// }


