import '../utils/datetime_utils.dart';

class EmployeeAttendanceStatus {
  final int employeeId;
  final String employeeName;
  final String username;
  final String? empCode;
  final String currentStatus;
  final String? clockInTime;
  final int elapsedWorkSeconds;
  final int elapsedBreakSeconds;

  const EmployeeAttendanceStatus({
    required this.employeeId,
    required this.employeeName,
    required this.username,
    this.empCode,
    required this.currentStatus,
    this.clockInTime,
    required this.elapsedWorkSeconds,
    required this.elapsedBreakSeconds,
  });

  factory EmployeeAttendanceStatus.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendanceStatus(
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      username: json['username'],
      empCode: json['emp_code'],
      currentStatus: json['current_status'],
      clockInTime: json['clock_in_time'],
      elapsedWorkSeconds: json['elapsed_work_seconds'] ?? 0,
      elapsedBreakSeconds: json['elapsed_break_seconds'] ?? 0,
    );
  }

  // Status helpers
  bool get isActive => currentStatus == 'active';
  bool get isOnBreak => currentStatus == 'break';
  bool get isClockedOut => currentStatus == 'ended';

  // Display helpers
  String get statusDisplay {
    switch (currentStatus) {
      case 'active':
        return 'Working';
      case 'break':
        return 'On Break';
      case 'ended':
        return 'Clocked Out';
      default:
        return 'Unknown';
    }
  }

  String get workDuration {
    final hours = elapsedWorkSeconds ~/ 3600;
    final minutes = (elapsedWorkSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String get displayName {
    if (empCode != null && empCode!.isNotEmpty && empCode != 'string') {
      return '$empCode - $employeeName';
    }
    return employeeName;
  }
}

class EmployeeAttendanceHistory {
  final String date;
  final String? firstClockIn;
  final String? lastClockOut;
  final int totalWorkSeconds;
  final int totalBreakSeconds;
  final int otSec;

  const EmployeeAttendanceHistory({
    required this.date,
    this.firstClockIn,
    this.lastClockOut,
    required this.totalWorkSeconds,
    required this.totalBreakSeconds,
    required this.otSec,
  });

  factory EmployeeAttendanceHistory.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendanceHistory(
      date: json['date'],
      firstClockIn: json['first_clock_in'],
      lastClockOut: json['last_clock_out'],
      totalWorkSeconds: json['total_work_seconds'] ?? 0,
      totalBreakSeconds: json['total_break_seconds'] ?? 0,
      otSec: json['ot_sec'] ?? 0,
    );
  }

  String get workDuration {
    final hours = totalWorkSeconds ~/ 3600;
    final minutes = (totalWorkSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String get breakDuration {
    final hours = totalBreakSeconds ~/ 3600;
    final minutes = (totalBreakSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String get status {
    final hours = totalWorkSeconds / 3600;
    if (hours >= 8) return 'ON TIME';
    if (hours >= 4) return 'PARTIAL';
    if (hours > 0) return 'LATE';
    return 'ABSENT';
  }

  String get clockInDisplay {
    return firstClockIn != null 
        ? DateTimeUtils.formatISTTime12(firstClockIn)
        : '--:--';
  }

  String get clockOutDisplay {
    return lastClockOut != null 
        ? DateTimeUtils.formatISTTime12(lastClockOut)
        : '--:--';
  }
}
