import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../services/admin_attendance_service.dart';
import '../models/admin_attendance_models.dart';
import '../utils/datetime_utils.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  List<EmployeeAttendanceStatus> _employees = [];
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final employees = await AdminAttendanceService.fetchAllEmployeesStatus();
      if (mounted) {
        setState(() {
          _employees = employees ?? [];
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load attendance data';
          _loading = false;
        });
      }
    }
  }

  List<EmployeeAttendanceStatus> get _filteredEmployees {
    var filtered = _employees.where((emp) {
      final matchesSearch = emp.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           emp.username.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'All' || 
                           (_statusFilter == 'Active' && emp.isActive) ||
                           (_statusFilter == 'Break' && emp.isOnBreak) ||
                           (_statusFilter == 'Clocked Out' && emp.isClockedOut);
      
      return matchesSearch && matchesStatus;
    }).toList();

    // Sort by status priority: Active > Break > Clocked Out
    filtered.sort((a, b) {
      final statusPriority = {'active': 0, 'break': 1, 'ended': 2};
      final aPriority = statusPriority[a.currentStatus] ?? 3;
      final bPriority = statusPriority[b.currentStatus] ?? 3;
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // If same status, sort by name
      return a.employeeName.compareTo(b.employeeName);
    });

    return filtered;
  }

  Future<void> _performAction(int employeeId, String action) async {
    final employee = _employees.firstWhere((e) => e.employeeId == employeeId);
    
    String? error;
    if (action == 'clock_in') {
      error = await AdminAttendanceService.clockInEmployee(employeeId);
    } else if (action == 'clock_out') {
      error = await AdminAttendanceService.clockOutEmployee(employeeId);
    }

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${employee.employeeName} ${action.replaceAll('_', ' ')}ed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ADMIN',
                style: GoogleFonts.nunito(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Attendance',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search employees...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Active', 'Break', 'Clocked Out'].map((status) {
                      final isSelected = _statusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _statusFilter = status),
                          selectedColor: Colors.red.shade100,
                          checkmarkColor: Colors.red.shade700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Summary Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Total', _employees.length.toString(), Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Active', _employees.where((e) => e.isActive).length.toString(), Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Break', _employees.where((e) => e.isOnBreak).length.toString(), Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Out', _employees.where((e) => e.isClockedOut).length.toString(), Colors.grey)),
              ],
            ),
          ),

          // Employee List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.nunito(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final employees = _filteredEmployees;
    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _statusFilter == 'All' 
                  ? 'No employees found'
                  : 'No employees match your filters',
              style: GoogleFonts.nunito(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: Colors.red,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) => _buildEmployeeCard(employees[index]),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeAttendanceStatus employee) {
    Color statusColor;
    IconData statusIcon;
    
    switch (employee.currentStatus) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.work;
        break;
      case 'break':
        statusColor = Colors.orange;
        statusIcon = Icons.coffee;
        break;
      case 'ended':
        statusColor = Colors.grey;
        statusIcon = Icons.home;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/admin/employee/${employee.employeeId}/attendance'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.employeeName,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '@${employee.username}',
                          style: GoogleFonts.nunito(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      employee.statusDisplay,
                      style: GoogleFonts.nunito(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (employee.clockInTime != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Started: ${DateTimeUtils.formatISTTime12(employee.clockInTime)}',
                      style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      'Work: ${employee.workDuration}',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: employee.isClockedOut 
                          ? () => _performAction(employee.employeeId, 'clock_in')
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: employee.isClockedOut ? Colors.green : Colors.grey.shade300),
                      ),
                      child: Text('Clock In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: !employee.isClockedOut 
                          ? () => _performAction(employee.employeeId, 'clock_out')
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: !employee.isClockedOut ? Colors.red : Colors.grey.shade300),
                      ),
                      child: Text('Clock Out'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => context.push('/admin/employee/${employee.employeeId}/attendance'),
                    icon: const Icon(Icons.history, color: Colors.blue),
                    tooltip: 'View History',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
