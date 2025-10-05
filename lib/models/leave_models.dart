import '../utils/datetime_utils.dart';

class LeaveRequest {
  final int id;
  final int employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final String leaveType;
  final String status;
  final String? reason;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.status,
    this.reason,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      employeeId: json['employee_id'],
      startDate: DateTimeUtils.parseISTDateTime(json['start_date'])!,
      endDate: DateTimeUtils.parseISTDateTime(json['end_date'])!,
      leaveType: json['leave_type'],
      status: json['status'],
      reason: json['reason'],
    );
  }

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'approved': return 'Approved';
      case 'denied': return 'Denied';
      default: return status;
    }
  }

  String get dateRangeDisplay {
    if (DateTimeUtils.isSameDay(startDate, endDate)) {
      return DateTimeUtils.formatISTDateFromDateTime(startDate);
    }
    return '${DateTimeUtils.formatISTDateFromDateTime(startDate)} - ${DateTimeUtils.formatISTDateFromDateTime(endDate)}';
  }
}

class LeaveRequestCreate {
  final DateTime startDate;
  final DateTime endDate;
  final String leaveType;
  final String? reason;

  const LeaveRequestCreate({
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    final isFullDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    String dateOnly(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
        'start_date': isFullDay ? dateOnly(startDate) : startDate.toIso8601String(),
        'end_date': isFullDay ? dateOnly(endDate) : endDate.toIso8601String(),
        'leave_type': leaveType,
        'reason': reason,
      };
    }


  int get durationInDays => endDate.difference(startDate).inDays + 1;
}

class LeaveBalance {
  final int availableCoins;
  final int rawAvailable;
  final List<ExpiringCoin> expiringSoon;
  final List<LeaveTransaction> recentTransactions;

  const LeaveBalance({
    required this.availableCoins,
    required this.rawAvailable,
    required this.expiringSoon,
    required this.recentTransactions,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      availableCoins: json['available_coins'],
      rawAvailable: json['raw_available'],
      expiringSoon: (json['expiring_soon'] as List).map((e) => ExpiringCoin.fromJson(e)).toList(),
      recentTransactions: (json['recent_txns'] as List).map((e) => LeaveTransaction.fromJson(e)).toList(),
    );
  }
}

class ExpiringCoin {
  final DateTime expiryDate;
  final int amount;

  const ExpiringCoin({required this.expiryDate, required this.amount});

  factory ExpiringCoin.fromJson(Map<String, dynamic> json) {
    return ExpiringCoin(
      expiryDate: DateTimeUtils.parseISTDateTime(json['expiry_date'])!,
      amount: json['amount'],
    );
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => daysUntilExpiry <= 60;
}

class LeaveTransaction {
  final String type;
  final int amount;
  final DateTime occurredAt;
  final String? comment;

  const LeaveTransaction({
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.comment,
  });

  factory LeaveTransaction.fromJson(Map<String, dynamic> json) {
    return LeaveTransaction(
      type: json['type'],
      amount: json['amount'],
      occurredAt: DateTimeUtils.parseISTDateTime(json['occurred_at'])!,
      comment: json['comment'],
    );
  }

  String get typeDisplay {
    switch (type) {
      case 'grant': return 'Granted';
      case 'consume': return 'Used';
      case 'expire': return 'Expired';
      case 'adjust': return 'Adjusted';
      case 'restore': return 'Restored';
      default: return type;
    }
  }

  String get amountDisplay {
    final sign = (type == 'consume' || type == 'expire') ? '-' : '+';
    return '$sign$amount';
  }
}
