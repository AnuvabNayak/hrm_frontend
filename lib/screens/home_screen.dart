import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/datetime_utils.dart';

// A utility class for handling break intervals.
class BreakInterval {
  DateTime start;
  DateTime? end;
  BreakInterval(this.start, [this.end]);
}

// A helper function to safely cast dynamic values to num, returning 0 if invalid.
num safeNum(dynamic x) => (x is num) ? x : 0;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //============================================================================
  // State Variables
  //============================================================================

  final _storage = const FlutterSecureStorage();
  
  // Data holders
  Map<String, dynamic>? active;
  Map<String, dynamic>? profile;
  Map<String, dynamic>? dailyQuote;
  Map<String, dynamic>? todayCompleted;
  List<dynamic> weekData = [];
  
  // UI & Loading state
  bool loading = true;
  String? error;
  bool _isActionLoading = false; // Prevents spamming action buttons

  // Timers and counters
  Timer? _pollingTimer; // For fetching data periodically from the server
  Timer? _uiTimer;      // For updating the UI timer every second
  int _displayedWorkSec = 0; // The value shown on the UI timer
  int _serverWorkSec = 0;    // The last known value from the server
  bool _counterRunning = false;

  // Break management
  List<BreakInterval> breakIntervals = [];
  BreakInterval? currentBreak;

  // Date tracking for daily data reset
  String? lastCompletedDate;


  //============================================================================
  // Lifecycle Methods
  //============================================================================

  @override
  void initState() {
    super.initState();
    _beginPolling();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _pollingTimer?.cancel();
    _uiTimer = null;
    _pollingTimer = null;
    _counterRunning = false;
    super.dispose();
  }

  //============================================================================
  // Core Logic & Data Fetching
  //============================================================================

  /// Initiates and manages the periodic fetching of attendance data.
  void _beginPolling() {
    _pollingTimer?.cancel();
    if (!mounted) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _fetchAndUpdate();
    });
    _fetchAndUpdate(); // Initial fetch
  }

  /// Fetches all required data from the backend API and updates the state.
  Future<void> _fetchAndUpdate() async {
    if (!mounted) return;
    if (loading == false) setState(() { loading = true; error = null; });

    try {
      final jwt = await _storage.read(key: "jwt");
      final auth = {"Authorization": "Bearer $jwt"};
      final baseUrl = "http://10.0.2.2:8000";

      // Fetch all data in parallel for better performance
      final responses = await Future.wait([
        http.get(Uri.parse("$baseUrl/attendance-rt/active"), headers: auth),
        http.get(Uri.parse("$baseUrl/attendance-rt/today-completed"), headers: auth),
        http.get(Uri.parse("$baseUrl/attendance-rt/recent?days=7"), headers: auth),
        http.get(Uri.parse("$baseUrl/employees/me"), headers: auth),
        http.get(Uri.parse("$baseUrl/inspiration/today"), headers: auth),
      ]);

      // Process Active Session Response
      if (responses[0].statusCode == 200) {
        active = jsonDecode(responses[0].body);
        _updateTimerState(active);
      }

      // Process Today's Completed Session Response
      if (responses[1].statusCode == 200) {
        if (_isNewDay()) todayCompleted = null;
        todayCompleted = jsonDecode(responses[1].body);
      } else {
        // Fallback if the endpoint fails or doesn't exist
        print("Today-completed endpoint not available or failed.");
      }

      // Process Week Data Response
      if (responses[2].statusCode == 200) {
        weekData = List.from(jsonDecode(responses[2].body));
      }

      // Process Profile Response
      if (responses[3].statusCode == 200) {
        profile = jsonDecode(responses[3].body);
      }
      
      // Process Daily Quote Response
      if (responses[4].statusCode == 200) {
        dailyQuote = jsonDecode(responses[4].body);
      }

    } catch (e) {
      if (mounted) error = "Failed to load data. Check connection.";
      print("❌ Fetch Error: $e");
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  /// Performs a state-changing action (e.g., clock-in, clock-out).
  Future<void> performAction(String endpoint) async {
    if (_isActionLoading || !mounted) return;
    setState(() { _isActionLoading = true; });

    try {
      final jwt = await _storage.read(key: "jwt");
      if (!mounted) return;

      final res = await http.post(
        Uri.parse("http://10.0.2.2:8000/attendance-rt/$endpoint"),
        headers: {"Authorization": "Bearer $jwt"},
      );

      if (!mounted) return;
      final json = jsonDecode(res.body);
      showSnack(json["message"] ?? (res.statusCode == 200 ? "Success" : "Action failed!"));
    } catch (e) {
      if (mounted) showSnack("Network error!");
    }

    await _fetchAndUpdate();
    if (mounted) setState(() { _isActionLoading = false; });
  }

  //============================================================================
  // Timer Management
  //============================================================================

  /// Updates the timer and break state based on the active session data.
  void _updateTimerState(Map<String, dynamic>? activeSession) {
    final sessionStatus = activeSession?['status'] ?? "ended";
    final onBreak = sessionStatus == "break";
    final isWorking = sessionStatus == "active";

    _serverWorkSec = safeNum(activeSession?['elapsed_work_seconds']).toInt();
    _displayedWorkSec = _serverWorkSec;

    // Manage break intervals
    if (onBreak && currentBreak == null) {
      currentBreak = BreakInterval(DateTime.now());
    }
    if (!onBreak && currentBreak != null) {
      currentBreak!.end = DateTime.now();
      breakIntervals.add(currentBreak!);
      currentBreak = null;
    }

    // Manage UI timer
    if (isWorking) {
      if (!_counterRunning) {
        _counterRunning = true;
        _runUiTimer();
      }
    } else {
      _counterRunning = false;
      _uiTimer?.cancel();
    }
  }
  
  /// Runs the 1-second UI timer to provide real-time feedback.
  void _runUiTimer() {
    _uiTimer?.cancel();
    if (!mounted) return;

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_counterRunning) {
        timer.cancel();
        _counterRunning = false;
        return;
      }
      
      setState(() {
        _displayedWorkSec = (_displayedWorkSec + 1).clamp(0, 36000);
        if (_displayedWorkSec >= 36000) {
          _counterRunning = false;
          timer.cancel();
        }
      });
    });
  }

  //============================================================================
  // UI Helpers & Getters
  //============================================================================
  
  /// Formats seconds into a HH:MM:SS string.
  String _formatHMS(num sec) {
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  /// Checks if the current date is different from the last recorded date.
  bool _isNewDay() {
    final todayStr = DateTimeUtils.formatISTDateFromDateTime(DateTime.now());
    if (lastCompletedDate != todayStr) {
      lastCompletedDate = todayStr;
      return true;
    }
    return false;
  }
  
  /// Provides a valid NetworkImage or null if the avatar URL is invalid.
  ImageProvider? _getValidAvatarImage() {
    final url = profile?['avatarUrl']?.toString();
    if (url != null && url.isNotEmpty && url != 'string') {
      return NetworkImage(url);
    }
    return null;
  }

  /// Returns a fallback Text widget for the avatar if no image is available.
  Widget? _getAvatarFallbackChild() {
    if (_getValidAvatarImage() != null) return null;
    
    final name = profile?['name'] ?? profile?['username'] ?? '';
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : "?",
      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
    );
  }
  
  //============================================================================
  // Action Handlers & Dialogs
  //============================================================================

  /// Displays a generic SnackBar message.
  void showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Handles the clock-out logic, showing a confirmation if clocking out early.
  void _handleClockOut() {
    final workHours = _displayedWorkSec / 3600.0;
    if (workHours < 8.0) {
      _showClockOutConfirmation(workHours);
    } else {
      performAction("clock-out");
    }
  }

  /// Shows a confirmation dialog for clocking out before 8 hours.
  void _showClockOutConfirmation(double workHours) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 28),
              const SizedBox(width: 12),
              Text("Early Clock Out", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("You are clocking out before completing 8 hours.", style: GoogleFonts.nunito(fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Current time: ${workHours.toStringAsFixed(1)} hours",
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No", style: GoogleFonts.nunito(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                performAction("clock-out");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Yes, Clock Out", style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  //============================================================================
  // Build Methods
  //============================================================================
  
  @override
  Widget build(BuildContext context) {
    final sessionStatus = active?['status'] ?? "ended";
    final onBreak = sessionStatus == "break";
    final clockedIn = sessionStatus == "active" || onBreak;
    final counterVal = _displayedWorkSec.clamp(0, 36000);
    final percent = (counterVal / 36000.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.arrow_back, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              DateTimeUtils.getCurrentISTDateWithDay(),
              style: GoogleFonts.nunito(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade400,
              backgroundImage: _getValidAvatarImage(),
              child: _getAvatarFallbackChild(),
            ),
          ),
        ],
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text(error!))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),
                    _buildTimerCircle(percent, counterVal, clockedIn, onBreak),
                    Text(
                      'Clocked at ${active?['clock_in_time'] != null ? DateTimeUtils.formatISTTime12(active!['clock_in_time']) : "--:--"}',
                      style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    _buildActionButtons(clockedIn, onBreak, counterVal),
                    const SizedBox(height: 30),
                    _buildActivityCard(sessionStatus),
                    const SizedBox(height: 8),
                    _buildInspirationCard(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
      bottomNavigationBar: const MyBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildTimerCircle(double percent, int counterVal, bool clockedIn, bool onBreak) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: percent),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: CircularPercentIndicator(
            radius: 110.0,
            lineWidth: 26.0,
            percent: value,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.grey.shade200,
            progressColor: onBreak ? Colors.amber : Colors.blueAccent,
            animation: true,
            animateFromLastPercent: true,
            center: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _formatHMS(counterVal),
                key: ValueKey(counterVal),
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: onBreak ? Colors.amber : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool clockedIn, bool onBreak, int counterVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: clockedIn
                  ? _BigActionButton(
                      key: const ValueKey('clock-out'),
                      label: "Clock Out",
                      color: Colors.grey[700]!,
                      onPressed: (onBreak || _isActionLoading) ? null : _handleClockOut,
                      rightText: DateTimeUtils.getCurrentISTTime12(),
                    )
                  : _BigActionButton(
                      key: const ValueKey('clock-in'),
                      label: "Clock In",
                      color: Colors.green,
                      onPressed: _isActionLoading ? null : () {
                        breakIntervals.clear();
                        currentBreak = null;
                        performAction("clock-in");
                      },
                      rightText: DateTimeUtils.getCurrentISTTime12(),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallActionButton(
                  color: Colors.blueAccent,
                  label: "Add Hours",
                  onPressed: _isActionLoading || clockedIn ? null : () => showSnack('Add Hours not implemented.'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SmallActionButton(
                  color: Colors.amber,
                  label: onBreak ? "Stop Break" : "Start Break",
                  onPressed: (!clockedIn || _isActionLoading) ? null : () {
                    if (onBreak) {
                      performAction("stop-break");
                    } else {
                      if (counterVal >= 36000) showSnack('Max duration reached!');
                      else performAction("start-break");
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String sessionStatus) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Column(
          children: [
            const SizedBox(height: 13),
            Text("Activity", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 17)),
            SizedBox(
              height: 110,
              child: _buildActivityContent(sessionStatus),
            ),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityContent(String sessionStatus) {
    if (sessionStatus != "ended") {
      return _ActivityPlaceholder(
        icon: Icons.access_time,
        text: "Clock out to see today's total",
      );
    }
    
    int totalWorkSec = 0;
    if (todayCompleted != null) {
      totalWorkSec = todayCompleted!['total_work_seconds'] ?? 0;
    } else if (weekData.isNotEmpty && DateTimeUtils.isToday(weekData.last['date'])) {
      totalWorkSec = safeNum(weekData.last['worked_sec']).toInt();
    }
    
    if (totalWorkSec == 0) {
      return _ActivityPlaceholder(
        icon: Icons.check_circle_outline,
        text: "No work completed today",
      );
    }
    
    final hours = totalWorkSec ~/ 3600;
    final minutes = (totalWorkSec % 3600) ~/ 60;
    final percent = (totalWorkSec / 36000.0).clamp(0.0, 1.0);
    
    return CircularPercentIndicator(
      radius: 44,
      lineWidth: 12,
      percent: percent,
      progressColor: Colors.blueAccent,
      center: Text(
        "${hours}h ${minutes}m clocked",
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      animation: true,
      animateFromLastPercent: true,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildInspirationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote, color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Daily Inspiration",
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dailyQuote?['text'] ?? "Keep going and stay motivated!",
                        style: GoogleFonts.nunito(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey.shade700, height: 1.4),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "— ${dailyQuote?['author'] ?? 'Unknown'}",
                        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//============================================================================
// Helper Widgets
//============================================================================

class _BigActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final String? rightText;
  const _BigActionButton({super.key, required this.label, required this.color, this.onPressed, this.rightText});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          if (rightText != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(rightText!, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  const _SmallActionButton({required this.label, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 3,
        shadowColor: color.withOpacity(0.3),
      ),
      child: Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }
}

class _ActivityPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ActivityPlaceholder({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}