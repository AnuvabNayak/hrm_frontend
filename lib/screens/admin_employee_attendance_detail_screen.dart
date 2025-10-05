import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_attendance_service.dart';
import '../models/admin_attendance_models.dart';
import '../utils/datetime_utils.dart';

class AdminEmployeeAttendanceDetailScreen extends StatefulWidget {
  final String employeeId;
  
  const AdminEmployeeAttendanceDetailScreen({
    Key? key,
    required this.employeeId,
  }) : super(key: key);

  @override
  State<AdminEmployeeAttendanceDetailScreen> createState() => _AdminEmployeeAttendanceDetailScreenState();
}

class _AdminEmployeeAttendanceDetailScreenState extends State<AdminEmployeeAttendanceDetailScreen> {
  List<EmployeeAttendanceHistory> _history = [];
  bool _loading = true;
  String? _error;
  String? _employeeName;
  int _days = 14;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final employeeId = int.parse(widget.employeeId);
      final history = await AdminAttendanceService.fetchEmployeeHistory(employeeId, days: _days);
      
      if (mounted) {
        setState(() {
          _history = history ?? [];
          _loading = false;
          
          // Try to get employee name from first record
          if (_history.isNotEmpty && _employeeName == null) {
            _employeeName = 'Employee #$employeeId';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load attendance history';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'ADMIN',
                    style: GoogleFonts.nunito(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Attendance History',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            if (_employeeName != null)
              Text(
                _employeeName!,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range, color: Colors.red),
            onSelected: (days) {
              setState(() => _days = days);
              _fetchHistory();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 14, child: Text('Last 14 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.nunito(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchHistory, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No attendance records found',
              style: GoogleFonts.nunito(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: Colors.red,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _history.length,
        itemBuilder: (context, index) => _AttendanceTimelineItem(
          item: _history[index],
          index: index,
          isFirst: index == 0,
        ),
      ),
    );
  }
}

class _AttendanceTimelineItem extends StatelessWidget {
  final EmployeeAttendanceHistory item;
  final int index;
  final bool isFirst;

  const _AttendanceTimelineItem({
    required this.item,
    required this.index,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Container(
          width: 50,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isFirst ? Colors.green : Colors.red.shade400,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (index < 13) // Don't show connector for last item
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.red.withOpacity(0.3),
                ),
            ],
          ),
        ),
        
        // Card content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16, bottom: 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and status row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.date,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            item.status,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Clock in/out times
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Clock In",
                              style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            Text(
                              item.clockInDisplay,
                              style: GoogleFonts.nunito(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Clock Out",
                              style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            Text(
                              item.clockOutDisplay,
                              style: GoogleFonts.nunito(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Work duration and break duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Work Hours",
                              style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            Text(
                              item.workDuration,
                              style: GoogleFonts.nunito(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Break Hours",
                              style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            Text(
                              item.breakDuration,
                              style: GoogleFonts.nunito(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ON TIME':
        return Colors.green;
      case 'PARTIAL':
        return Colors.orange;
      case 'LATE':
        return Colors.orange;
      case 'ABSENT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
