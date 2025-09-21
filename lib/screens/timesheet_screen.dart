import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({Key? key}) : super(key: key);

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final _storage = const FlutterSecureStorage();
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> attendanceHistory = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchTimesheetHistory();
    // Refresh every 30 seconds to catch new clock-outs
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchTimesheetHistory();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTimesheetHistory() async {
    if (!mounted) return;
    
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final jwt = await _storage.read(key: "jwt");
      if (jwt == null) {
        setState(() => error = "Not authenticated");
        return;
      }

      // Use existing endpoint that already works
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/attendance-rt/recent?days=14"),
        headers: {"Authorization": "Bearer $jwt"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Process the data to match our timesheet format
        final processed = _processRecentData(data);
        
        setState(() {
          attendanceHistory = processed;
          loading = false;
        });
      } else {
        setState(() {
          error = "Failed to load timesheet data";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Network error: $e";
        loading = false;
      });
    }
  }
  List<Map<String, dynamic>> _processRecentData(List<dynamic> rawData) {
  List<Map<String, dynamic>> processed = [];
  
  for (int i = 0; i < rawData.length; i++) {
    final dayData = rawData[i];
    
    // Use correct field names from backend
    final workedSec = (dayData['total_work_seconds'] ?? 0).toInt();
    final breakSec = (dayData['total_break_seconds'] ?? 0).toInt();
    
    // Skip only if there's truly no work done
    if (workedSec <= 0) continue;
    
    // Parse the date from the API response
    DateTime dayDate;
    if (dayData['first_clock_in'] != null) {
      dayDate = DateTime.parse(dayData['first_clock_in']);
    } else {
      // Fallback to estimated date
      final now = DateTime.now();
      dayDate = now.subtract(Duration(days: rawData.length - 1 - i));
    }
    
    // Format work duration
    final workHours = workedSec ~/ 3600;
    final workMinutes = (workedSec % 3600) ~/ 60;
    
    // Format break duration
    final breakHours = breakSec ~/ 3600;
    final breakMinutesRem = (breakSec % 3600) ~/ 60;
    
    // Use actual clock in/out times from API
    final clockInTime = dayData['first_clock_in'] != null 
        ? _formatTimeFromString(dayData['first_clock_in'])
        : "9:00 AM";
    
    final clockOutTime = dayData['last_clock_out'] != null 
        ? _formatTimeFromString(dayData['last_clock_out'])
        : "-";
    
    processed.add({
      "id": i,
      "date": _formatDate(dayDate),
      "full_date": "${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}",
      "day_name": _getDayName(dayDate.weekday),
      "clock_in_time": clockInTime,
      "clock_out_time": clockOutTime,
      "work_duration": "${workHours}h ${workMinutes}m",
      "break_duration": "${breakHours}h ${breakMinutesRem}m",
      "status": workHours >= 8 ? "ON TIME" : "PARTIAL",
      "shift_info": "Work From Home - ${_formatTimeFromString(dayData['first_clock_in'])} - ${dayData['last_clock_out'] != null ? _formatTimeFromString(dayData['last_clock_out']) : 'Active'}"
    });
  }
  
  // Reverse to show most recent first
  return processed.reversed.toList();
}

// Add this helper function to format time strings
String _formatTimeFromString(String? dateTimeString) {
  if (dateTimeString == null) return "-";
  
  try {
    final dateTime = DateTime.parse(dateTimeString);
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $ampm";
  } catch (e) {
    return "-";
  }
}
  // List<Map<String, dynamic>> _processRecentData(List<dynamic> rawData) {
  //   List<Map<String, dynamic>> processed = [];
    
  //   for (int i = 0; i < rawData.length; i++) {
  //     final dayData = rawData[i];
      
  //     // Skip days with no work or incomplete sessions
  //     if (dayData['worked_sec'] == null || dayData['worked_sec'] == 0) {
  //       continue;
  //     }
      
  //     // Only show completed sessions (those with actual work time)
  //     final workedSec = (dayData['worked_sec'] ?? 0).toInt();
  //     final breakSec = (dayData['break_sec'] ?? 0).toInt();
      
  //     if (workedSec <= 0) continue;
      
  //     // Format work duration
  //     final workHours = workedSec ~/ 3600;
  //     final workMinutes = (workedSec % 3600) ~/ 60;
      
  //     // Format break duration
  //     final breakHours = breakSec ~/ 3600;
  //     final breakMinutesRem = (breakSec % 3600) ~/ 60;
      
  //     // Calculate estimated times (since we don't have exact clock in/out from this endpoint)
  //     final now = DateTime.now();
  //     final dayDate = now.subtract(Duration(days: rawData.length - 1 - i));
      
  //     // Estimate clock in at 9:00 AM and clock out based on work duration
  //     final estimatedClockIn = DateTime(dayDate.year, dayDate.month, dayDate.day, 9, 0);
  //     final estimatedClockOut = estimatedClockIn.add(Duration(seconds: workedSec + breakSec));
      
  //     processed.add({
  //       "id": i,
  //       "date": _formatDate(dayDate),
  //       "full_date": "${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}",
  //       "day_name": _getDayName(dayDate.weekday),
  //       "clock_in_time": _formatTime(estimatedClockIn),
  //       "clock_out_time": _formatTime(estimatedClockOut),
  //       "work_duration": "${workHours}h ${workMinutes}m",
  //       "break_duration": "${breakHours}h ${breakMinutesRem}m",
  //       "status": workHours >= 8 ? "ON TIME" : "PARTIAL",
  //       "shift_info": "Work From Home"
  //     });
  //   }
    
  //   // Reverse to show most recent first
  //   return processed.reversed.toList();
  // }

  String _formatDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return "${days[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')}";
  }

  String _getDayName(int weekday) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  // String _formatTime(DateTime time) {
  //   final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
  //   final minute = time.minute.toString().padLeft(2, '0');
  //   final ampm = time.hour >= 12 ? 'PM' : 'AM';
  //   return "$hour:$minute $ampm";
  // }

  Future<void> _onRefresh() async {
    await _fetchTimesheetHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Timesheets",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 22
          )
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTimesheetHistory,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(),
      ),
      bottomNavigationBar: MyBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              error!,
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTimesheetHistory,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (attendanceHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No attendance records found",
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              "Start clocking in to see your timesheet history",
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: attendanceHistory.length,
      itemBuilder: (context, index) {
        return _AttendanceTimelineItem(
          item: attendanceHistory[index],
          index: index,
          isFirst: index == 0,
        );
      },
    );
  }
}

class _AttendanceTimelineItem extends StatelessWidget {
  final Map<String, dynamic> item;
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
                  color: isFirst ? Colors.green : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                  ),
                ),
              ),
              if (index < 13) // Don't show connector for last item
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.blue.withValues(alpha: 0.3),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                          item['date'] ?? '-',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item['status'] ?? ''),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            item['status'] ?? 'UNKNOWN',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Work from home info
                    Text(
                      item['shift_info'] ?? 'Work From Home',
                      style: GoogleFonts.nunito(
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
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
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item['clock_in_time'] ?? '-',
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
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item['clock_out_time'] ?? '-',
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
                              "Effective Hours",
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item['work_duration'] ?? '0h 0m',
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
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item['break_duration'] ?? '0h 0m',
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
