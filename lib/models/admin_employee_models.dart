class CreateEmployeeRequest {
  final String username;
  final String password;
  final String role;
  final String name;
  final String? email;
  final String? phone;
  final String? empCode;

  const CreateEmployeeRequest({
    required this.username,
    required this.password,
    required this.role,
    required this.name,
    this.email,
    this.phone,
    this.empCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_data': {
        'username': username,
        'password': password,
        'role': role,
      },
      'employee_data': {
        'name': name,
        'email': email,
        'phone': phone,
        'emp_code': empCode,
        'user_id': 0, // Will be set by backend
      },
    };
  }
}

class AdminEmployee {
  final int id;
  final String name;
  final int userId;
  final String? email;
  final String? phone;
  final String? empCode;
  final String? username;

  const AdminEmployee({
    required this.id,
    required this.name,
    required this.userId,
    this.email,
    this.phone,
    this.empCode,
    this.username,
  });

  factory AdminEmployee.fromJson(Map<String, dynamic> json) {
    return AdminEmployee(
      id: json['id'],
      name: json['name'],
      userId: json['user_id'],
      email: json['email'],
      phone: json['phone'],
      empCode: json['emp_code'],
      username: json['username'],
    );
  }

  String get displayName {
    if (empCode != null && empCode!.isNotEmpty && empCode != 'string') {
      return '$empCode - $name';
    }
    return name;
  }

  String get displayEmail => email ?? 'No email';
  String get displayPhone => phone ?? 'No phone';
  String get displayUsername => '@${username ?? 'No username'}';
}

class UpdateEmployeeRequest {
  final String? name;
  final String? email;
  final String? phone;
  final String? empCode;

  const UpdateEmployeeRequest({
    this.name,
    this.email,
    this.phone,
    this.empCode,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (empCode != null) data['emp_code'] = empCode;
    return data;
  }
}
