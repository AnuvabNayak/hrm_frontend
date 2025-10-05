import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../services/auth_service.dart';
import '../utils/datetime_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/profile_service.dart';
import '../models/profile_model.dart';



class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _storage = const FlutterSecureStorage();
  Timer? _clockTimer;
  String _currentTime = '';
  // Added properties from the patch
  ProfileModel? _profile;
  Map<String, dynamic>? _activeSession;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    // Updated initState from the patch
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _fetchProfile();
    _fetchActiveSession();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateTimeUtils.getCurrentISTTime12();
    });
  }

  // Added methods from the patch
  Future<void> _fetchProfile() async {
    try {
      final jwt = await _storage.read(key: 'jwt');
      if (jwt == null) return;
      
      final profile = await ProfileService.fetchProfile(jwt);
      if (mounted) {
        setState(() => _profile = profile);
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _fetchActiveSession() async {
    try {
      final jwt = await _storage.read(key: 'jwt');
      if (jwt == null) return;
      
      final res = await http.get(
        Uri.parse('http://10.0.2.2:8000/attendance-rt/active'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() => _activeSession = data);
        }
      }
    } catch (e) {
      print('Error fetching active session: $e');
    }
  }

  Future<void> _performAttendanceAction(String action) async {
    setState(() => _isActionLoading = true);
    
    try {
      final jwt = await _storage.read(key: 'jwt');
      final res = await http.post(
        Uri.parse('http://10.0.2.2:8000/attendance-rt/$action'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      
      final data = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Action completed'),
            backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
          ),
        );
        _fetchActiveSession(); // Refresh session data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      context.go('/');
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
              'Dashboard',
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
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Time',
                        style: GoogleFonts.nunito(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentTime,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateTimeUtils.getCurrentISTDateWithDay(),
                        style: GoogleFonts.nunito(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.admin_panel_settings,
                    size: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions Grid
            Text(
              'Quick Actions',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickActionCard(
                  'Manage Employees',
                  Icons.people,
                  Colors.blue,
                  () => context.go('/admin/employees'),
                ),
                _buildQuickActionCard(
                  'View Attendance',
                  Icons.access_time,
                  Colors.green,
                  () => context.go('/admin/attendance'),
                ),
                _buildQuickActionCard(
                  'Leave Requests',
                  Icons.event_available,
                  Colors.orange,
                  () => context.go('/admin/leaves'),
                ),
                _buildQuickActionCard(
                  'Create Posts',
                  Icons.announcement,
                  Colors.purple,
                  () => context.go('/admin/posts'),
                ),
              ],
            ),
            
            // Added Admin Personal Attendance Card from the patch
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'My Attendance',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_activeSession != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_activeSession!['status'] == 'active') 
                                ? Colors.green.withOpacity(0.1)
                                : (_activeSession!['status'] == 'break')
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (_activeSession!['status'] == 'active') 
                                ? 'Working'
                                : (_activeSession!['status'] == 'break')
                                    ? 'On Break'
                                    : 'Clocked Out',
                            style: GoogleFonts.nunito(
                              color: (_activeSession!['status'] == 'active') 
                                  ? Colors.green.shade700
                                  : (_activeSession!['status'] == 'break')
                                      ? Colors.orange.shade700
                                      : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_activeSession!['clock_in_time'] != null)
                          Text(
                            'Since ${DateTimeUtils.formatISTTime12(_activeSession!['clock_in_time'])}',
                            style: GoogleFonts.nunito(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (_isActionLoading || (_activeSession?['status'] != 'ended')) 
                              ? null
                              : () => _performAttendanceAction('clock-in'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                          child: const Text('Clock In'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (_isActionLoading || (_activeSession?['status'] == 'ended')) 
                              ? null
                              : () => _performAttendanceAction('clock-out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Clock Out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // System Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'System Information',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Zytexa HRM Admin Panel\nVersion 1.0.0\nTimezone: IST (UTC+5:30)',
                    style: GoogleFonts.nunito(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
