import '../utils/datetime_utils.dart';

class AdminLeaveRequest {
  final int id;
  final int employeeId;
  final String startDate;
  final String endDate;
  final String leaveType;
  final String status;
  final String? reason;
  final String? employeeName;
  final String? empCode;

  const AdminLeaveRequest({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.status,
    this.reason,
    this.employeeName,
    this.empCode,
  });

  factory AdminLeaveRequest.fromJson(Map<String, dynamic> json) {
    return AdminLeaveRequest(
      id: json['id'],
      employeeId: json['employee_id'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      leaveType: json['leave_type'],
      status: json['status'],
      reason: json['reason'],
      employeeName: json['employee_name'],
      empCode: json['emp_code'],
    );
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';

  // Duration calculation
  int get durationDays {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays + 1;
    } catch (e) {
      return 1;
    }
  }

  // Display helpers
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'denied':
        return 'Denied';
      default:
        return status;
    }
  }

  String get employeeDisplay {
    if (empCode != null && empCode!.isNotEmpty && empCode != 'string') {
      return '$empCode - ${employeeName ?? 'Unknown'}';
    }
    return employeeName ?? 'Employee #$employeeId';
  }

  String get dateRangeDisplay {
    final startDisplay = DateTimeUtils.formatISTDateWithDay(startDate);
    final endDisplay = DateTimeUtils.formatISTDateWithDay(endDate);
    
    if (startDate == endDate) {
      return startDisplay;
    }
    return '$startDisplay to $endDisplay';
  }
  

  String get leaveTypeDisplay {
    switch (leaveType.toLowerCase()) {
      case 'vacation':
        return 'Vacation Leave';
      case 'sick':
        return 'Sick Leave';
      case 'personal':
        return 'Personal Leave';
      case 'emergency':
        return 'Emergency Leave';
      default:
        return leaveType;
    }
  }
}

class EmployeeBasic {
  final int id;
  final String name;
  final String? empCode;
  final String? username;

  const EmployeeBasic({
    required this.id,
    required this.name,
    this.empCode,
    this.username,
  });

  factory EmployeeBasic.fromJson(Map<String, dynamic> json) {
    return EmployeeBasic(
      id: json['id'],
      name: json['name'],
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
}
