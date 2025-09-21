class ProfileModel {
  final String name;
  final int employeeId;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? empCode;
  final String? username;
  // Add more fields if backend returns them

  ProfileModel({
    required this.name,
    required this.employeeId,
    this.email,
    this.phone,
    this.avatarUrl,
    this.empCode,
    this.username,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'] ?? '-',
      employeeId: json['id'] ?? 0,
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      empCode: json['emp_code'],
      username: json['username'],
    );
  }
}
