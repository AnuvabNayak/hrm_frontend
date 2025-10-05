import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../services/admin_leave_service.dart';
import '../models/admin_leave_models.dart';

class AdminLeaveApprovalScreen extends StatefulWidget {
  const AdminLeaveApprovalScreen({Key? key}) : super(key: key);

  @override
  State<AdminLeaveApprovalScreen> createState() => _AdminLeaveApprovalScreenState();
}

class _AdminLeaveApprovalScreenState extends State<AdminLeaveApprovalScreen> {
  List<AdminLeaveRequest> _requests = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await AdminLeaveService.fetchAllLeaveRequests(limit: 100);
      if (mounted) {
        setState(() {
          _requests = requests ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load leave requests';
          _loading = false;
        });
      }
    }
  }

  List<AdminLeaveRequest> get _filteredRequests {
    var filtered = _requests.where((req) {
      final matchesSearch = req.employeeDisplay.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           req.leaveTypeDisplay.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           (req.reason ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'All' || 
                           (_statusFilter == 'Pending' && req.isPending) ||
                           (_statusFilter == 'Approved' && req.isApproved) ||
                           (_statusFilter == 'Denied' && req.isDenied);
      
      return matchesSearch && matchesStatus;
    }).toList();

    // Sort by status priority: Pending first, then by date
    filtered.sort((a, b) {
      if (a.isPending && !b.isPending) return -1;
      if (!a.isPending && b.isPending) return 1;
      
      // If same status, sort by start date (newest first)
      try {
        final aDate = DateTime.parse(a.startDate);
        final bDate = DateTime.parse(b.startDate);
        return bDate.compareTo(aDate);
      } catch (e) {
        return 0;
      }
    });

    return filtered;
  }

  Future<void> _performAction(AdminLeaveRequest request, String action) async {
    final confirmAction = action == 'approve' ? 'Approve' : 'Deny';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$confirmAction Leave Request'),
        content: Text('Are you sure you want to $action this leave request for ${request.employeeDisplay}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
            ),
            child: Text(confirmAction, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    String? error;
    if (action == 'approve') {
      error = await AdminLeaveService.approveLeaveRequest(request.id);
    } else if (action == 'deny') {
      error = await AdminLeaveService.denyLeaveRequest(request.id);
    }

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request ${action}d successfully'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.orange,
          ),
        );
        _fetchRequests(); // Refresh data
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
              'Leave Requests',
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
            onPressed: _fetchRequests,
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
                    hintText: 'Search by employee, leave type, or reason...',
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
                    children: ['All', 'Pending', 'Approved', 'Denied'].map((status) {
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
                Expanded(child: _buildStatCard('Total', _requests.length.toString(), Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Pending', _requests.where((r) => r.isPending).length.toString(), Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Approved', _requests.where((r) => r.isApproved).length.toString(), Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Denied', _requests.where((r) => r.isDenied).length.toString(), Colors.red)),
              ],
            ),
          ),

          // Requests List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
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
            ElevatedButton(onPressed: _fetchRequests, child: const Text('Retry')),
          ],
        ),
      );
    }

    final requests = _filteredRequests;
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _statusFilter == 'All' 
                  ? 'No leave requests found'
                  : 'No requests match your filters',
              style: GoogleFonts.nunito(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: Colors.red,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) => _buildLeaveRequestCard(requests[index]),
      ),
    );
  }

  Widget _buildLeaveRequestCard(AdminLeaveRequest request) {
    Color statusColor;
    IconData statusIcon;
    
    if (request.isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    } else if (request.isApproved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        request.employeeDisplay,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        request.leaveTypeDisplay,
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
                    request.statusDisplay,
                    style: GoogleFonts.nunito(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  request.dateRangeDisplay,
                  style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${request.durationDays} day${request.durationDays > 1 ? 's' : ''}',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${request.reason}',
                style: GoogleFonts.nunito(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            if (request.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _performAction(request, 'deny'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Deny'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _performAction(request, 'approve'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
