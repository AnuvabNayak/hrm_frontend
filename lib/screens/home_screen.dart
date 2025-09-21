// home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';

num safeNum(dynamic x) => (x is num) ? x : 0;

class BreakInterval {
  DateTime start;
  DateTime? end;
  BreakInterval(this.start, [this.end]);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  Map? active;
  Map? profile;
  List weekData = [];
  bool loading = true;
  String? error;

  Timer? _pollingTimer;
  Timer? _uiTimer;
  int _displayedWorkSec = 0;
  int _serverWorkSec = 0;
  bool _counterRunning = false;
  bool _isActionLoading = false;
  DateTime? _clockedAt;
  List<BreakInterval> breakIntervals = [];
  BreakInterval? currentBreak;

  ImageProvider? _getValidAvatarImage() {
  // Check if profile has valid avatar URL
  if (profile?['avatarUrl'] != null && 
      profile!['avatarUrl'].toString().isNotEmpty &&
      profile!['avatarUrl'].toString() != 'string') {
    return NetworkImage(profile!['avatarUrl']);
  }
  return null;
}

  Widget? _getAvatarFallbackChild() {
    // Only show fallback if no valid image
    if (_getValidAvatarImage() == null) {
      final name = profile?['name'] ?? profile?['username'] ?? '';
      return Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return null;
  }

  Map<String, dynamic>? dailyQuote;
  // List<Map<String, dynamic>> recentQuotes = [];
  // String currentTheme = "motivation";  

  // update for activity component
  Map<String, dynamic>? todayCompleted;
  String? lastCompletedDate;
  //method to check if it's a new day
  bool _isNewDay() {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    if (lastCompletedDate != todayStr) {
      lastCompletedDate = todayStr;
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _beginPolling();
  }

@override
void dispose() {
  _uiTimer?.cancel();
  _pollingTimer?.cancel();
  super.dispose();
}

void _beginPolling() {
  _pollingTimer?.cancel();
  _pollingTimer = Timer.periodic(const Duration(seconds: 25), (t) {
    if (mounted) _fetchAndUpdate();
  });
  _fetchAndUpdate();
}

  Future _fetchAndUpdate() async {
  if (!mounted) return;
  setState(() { loading = true; error = null; });
  
  try {
    final jwt = await _storage.read(key: "jwt");
    final auth = {"Authorization": "Bearer $jwt"};
    
    // Fetch active session data
    final activeRes = await http.get(
      Uri.parse("http://10.0.2.2:8000/attendance-rt/active"),
      headers: auth
    );
    
    if (activeRes.statusCode == 200) {
      active = jsonDecode(activeRes.body);

      // Consistent state logic: only use status!
      final sessionStatus = active?['status'] ?? "ended";
      final clockedIn = sessionStatus == "active" || sessionStatus == "break";
      final onBreak = sessionStatus == "break";

      final netWorkSec = safeNum(active?['elapsed_work_seconds']).toInt();
      _clockedAt = active?['clock_in_time'] != null
          ? DateTime.tryParse(active!['clock_in_time'])
          : null;
      _serverWorkSec = netWorkSec;
      _displayedWorkSec = _serverWorkSec;

      if (onBreak && currentBreak == null) {
        currentBreak = BreakInterval(DateTime.now());
      }
      if (!onBreak && currentBreak != null) {
        currentBreak!.end = DateTime.now();
        breakIntervals.add(currentBreak!);
        currentBreak = null;
      }
      if (clockedIn && !onBreak) {
        if (!_counterRunning) {
          _counterRunning = true;
          _runUiTimer();
        }
      } else {
        _counterRunning = false;
        _uiTimer?.cancel();
      }
    }

    // Fetch today's completed sessions
    try {
      final todayRes = await http.get(
        Uri.parse("http://10.0.2.2:8000/attendance-rt/today-completed"),
        headers: auth
      );
      
      if (todayRes.statusCode == 200) {
        final newTodayData = jsonDecode(todayRes.body);
        
        // Reset if it's a new day
        if (_isNewDay()) {
          todayCompleted = null;
        }
        
        todayCompleted = newTodayData;
      }
    } catch (e) {
      // If today-completed endpoint doesn't exist, todayCompleted remains null
      // The app will fall back to using weekData for today's information
      print("Today-completed endpoint not available: $e");
    }

    // Fetch week data
    final weekRes = await http.get(
      Uri.parse("http://10.0.2.2:8000/attendance-rt/recent?days=7"), 
      headers: auth
    );
    if (weekRes.statusCode == 200) {
      weekData = List.from(jsonDecode(weekRes.body));
    }

    // Fetch profile data
    final profRes = await http.get(
      Uri.parse("http://10.0.2.2:8000/employees/me"),
      headers: auth
    );
    if (profRes.statusCode == 200) {
      profile = jsonDecode(profRes.body);
    }
    
    // Fetch daily quote
    final quoteRes = await http.get(
      Uri.parse("http://10.0.2.2:8000/inspiration/today"),
      headers: auth,
    );
    if (quoteRes.statusCode == 200) {
      dailyQuote = jsonDecode(quoteRes.body);
    }



  } catch (e) {
    error = "Failed to load data";
  }
  
  setState(() {
    loading = false;
  });
}
//   Future<void> _fetchQuoteHistory() async {
//   try {
//     final jwt = await _storage.read(key: "jwt");
//     final response = await http.get(
//       Uri.parse("http://10.0.2.2:8000/inspiration/history?days=3"),
//       headers: {"Authorization": "Bearer $jwt"},
//     );
    
//     if (response.statusCode == 200) {
//       final List<dynamic> quotes = jsonDecode(response.body);
//       print("Quote history loaded: ${quotes.length} quotes");
//       // You can store this in state if you want to display multiple quotes
//     }
//   } catch (e) {
//     print("Failed to load quote history: $e");
//   }
// }

  void _runUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final sessionStatus = active?['status'] ?? "ended";
      final clockedIn = sessionStatus == "active" || sessionStatus == "break";
      final onBreak = sessionStatus == "break";

      if (!(clockedIn && !onBreak)) return;
      setState(() {
        _displayedWorkSec = (_displayedWorkSec + 1).clamp(0, 36000);
        if (_displayedWorkSec >= 36000) {
          _displayedWorkSec = 36000;
          _counterRunning = false;
          _uiTimer?.cancel();
        }
      });
    });
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Duration get totalBreak {
    int sum = 0;
    for (var br in breakIntervals) {
      if (br.end != null) {
        sum += br.end!.difference(br.start).inSeconds;
      }
    }
    if (currentBreak != null && currentBreak!.end == null) {
      sum += DateTime.now().difference(currentBreak!.start).inSeconds;
    }
    return Duration(seconds: sum);
  }

  int get netWorkSec {
    final gross = _displayedWorkSec;
    final breakSec = totalBreak.inSeconds;
    final net = gross - breakSec;
    return net.clamp(0, 36000);
  }

  Future<void> performAction(String endpoint) async {
    setState(() { _isActionLoading = true; });
    try {
      final jwt = await _storage.read(key: "jwt");
      final res = await http.post(
        Uri.parse("http://10.0.2.2:8000/attendance-rt/$endpoint"),
        headers: {"Authorization": "Bearer $jwt"},
      );
      final json = jsonDecode(res.body);
      if (res.statusCode == 200) {
        showSnack(json["message"] ?? "Success");
      } else {
        showSnack(json["message"] ?? "Action failed!");
      }
    } catch (e) {
      showSnack("Network error!");
    }
    await _fetchAndUpdate();
    setState(() { _isActionLoading = false; });
  }

  String _formatHMS(num sec) {
    final h = (sec ~/ 3600).toString().padLeft(2,'0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2,'0');
    final s = (sec % 60).toString().padLeft(2,'0');
    return "$h:$m:$s";
  }

  String _formatReadable(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    final min = dt.minute.toString().padLeft(2, '0');
    return "$hour:$min $ampm";
  }

  // Add this new method to build activity content
  Widget _buildActivityContent(String sessionStatus) {
    // Don't show completed work during active sessions or breaks
    if (sessionStatus != "ended") {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              "Clock out to see today's total",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      );
    }
    
    // Get today's work data - prioritize todayCompleted if available, otherwise use weekData
    int totalWorkSec = 0;
    
    if (todayCompleted != null) {
      totalWorkSec = todayCompleted!['total_work_seconds'] ?? 0;
    } else if (weekData.isNotEmpty) {
      // Fallback to weekData (last item should be today)
      final todayData = weekData.last;
      totalWorkSec = safeNum(todayData['worked_sec']).toInt();
    }
    
    if (totalWorkSec == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              "No work completed today",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sessionStatus = active?['status'] ?? "ended";
    final onBreak = sessionStatus == "break";
    final clockedIn = sessionStatus == "active" || sessionStatus == "break";
    final counterVal = _displayedWorkSec.clamp(0, 36000);
    final percent = (counterVal / 36000.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        centerTitle: false, automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.arrow_back, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2,'0')}-${now.year}",
              style: GoogleFonts.nunito(
                  color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CircleAvatar(
              // backgroundImage: profile?['photoUrl'] != null
              //   ? NetworkImage(profile!['photoUrl'])
              //   : const AssetImage("assets/profilepic.png") as ImageProvider,
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
        : error != null ? Center(child: Text(error!)) : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                // Timer Circle
                TweenAnimationBuilder(
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
                              color: clockedIn
                                ? (onBreak ? Colors.amber : Colors.black)
                                : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
                Text(
                  'Clocked at ${_clockedAt != null ? _formatReadable(_clockedAt!) : "--"}',
                  style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: clockedIn
                            ? _BigActionButton(
                                label: "Clock Out",
                                color: Colors.grey[700]!,
                                onPressed: (onBreak || _isActionLoading)
                                  ? null
                                  : () {
                                      performAction("clock-out");
                                    },
                                rightText: now.toString().substring(11,16),
                              )
                            : _BigActionButton(
                                label: "Clock In",
                                color: Colors.green,
                                onPressed: _isActionLoading
                                  ? null
                                  : () {
                                      breakIntervals.clear();
                                      currentBreak = null;
                                      performAction("clock-in");
                                    },
                                rightText: TimeOfDay.now().format(context),
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
                              onPressed: _isActionLoading || clockedIn
                                ? null
                                : () { showSnack('Add Hours not implemented.'); },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SmallActionButton(
                              color: Colors.amber,
                              label: (!clockedIn) ? "Start Break" : (onBreak ? "Stop Break" : "Start Break"),
                              onPressed: (!clockedIn || _isActionLoading)
                                ? null
                                : () {
                                    if (!onBreak) {
                                      if (counterVal >= 36000) {
                                        showSnack('Max duration reached!');
                                      } else {
                                        performAction("start-break");
                                      }
                                    } else {
                                      performAction("stop-break");
                                    }
                                  },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Activity donut
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Column(
                      children: [
                        const SizedBox(height: 13),
                        Text("Activity",
                          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 17)),
                        SizedBox(
                          height: 110,
                          child: _buildActivityContent(sessionStatus),
                        ),
                        const SizedBox(height: 7),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                // Daily Quote Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Container(
                      height: 180, // Same height as the previous chart
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.format_quote,
                                color: Colors.blue.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Daily Inspiration",
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
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
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "— ${dailyQuote?['author'] ?? 'Unknown'}",
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tracked Hours Bar Chart
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 10.0),
                //   child: Card(
                //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                //     elevation: 4,
                //     child: Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 15),
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text("Tracked Hours",
                //             style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                //           const SizedBox(height: 5),
                //           SizedBox(
                //             height: 127,
                //             child: BarChart(
                //               BarChartData(
                //                 alignment: BarChartAlignment.spaceAround,
                //                 maxY: 14,
                //                 minY: 0,
                //                 barTouchData: BarTouchData(enabled: true),
                //                 gridData: FlGridData(show: true),
                //                 barGroups: List.generate(weekData.length, (i) {
                //                   final wd = weekData[i];
                //                   final isToday = i == weekData.length - 1; // Last item is today
                                  
                //                   return BarChartGroupData(
                //                     x: i,
                //                     barRods: [
                //                       BarChartRodData(
                //                         toY: safeNum(wd['worked_sec']) / 3600.0,
                //                         width: isToday ? 16 : 14, // Wider bar for today
                //                         color: isToday ? Colors.blue.shade700 : Colors.blueAccent,
                //                       ),
                //                       BarChartRodData(
                //                         toY: safeNum(wd['break_sec']) / 3600.0,
                //                         width: isToday ? 8 : 7,
                //                         color: Colors.amber,
                //                       ),
                //                       BarChartRodData(
                //                         toY: safeNum(wd['ot_sec']) / 3600.0,
                //                         width: isToday ? 8 : 7,
                //                         color: Colors.redAccent,
                //                       ),
                //                     ],
                //                   );
                //                 }),
                //                 borderData: FlBorderData(show: false),
                //                 titlesData: FlTitlesData(
                //                   leftTitles: AxisTitles(
                //                     sideTitles: SideTitles(showTitles:true, reservedSize:22,
                //                       getTitlesWidget: (val, meta) =>
                //                         Text("${val.toInt()}h",
                //                             style: GoogleFonts.nunito(fontSize:10))),
                //                   ),
                //                   bottomTitles: AxisTitles(
                //                     sideTitles: SideTitles(
                //                       showTitles: true, 
                //                       getTitlesWidget: (val, meta) {
                //                         final weekday = ['M','T','W','T','F','S','S'];
                //                         final isToday = val.toInt() == weekData.length - 1;
                //                         return Text(
                //                           weekday[val.toInt() % 7],
                //                           style: GoogleFonts.nunito(
                //                             fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                //                             color: isToday ? Colors.blue.shade700 : Colors.black,
                //                             fontSize: isToday ? 12 : 11,
                //                           ),
                //                         );
                //                       }
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ),
                //           ),
                //           const SizedBox(height: 7),
                //           Row(
                //             children: [
                //               _LegendItem(color: Colors.blueAccent, label: "Worked"),
                //               const SizedBox(width: 8),
                //               _LegendItem(color: Colors.amber, label: "Breaks"),
                //               const SizedBox(width: 8),
                //               _LegendItem(color: Colors.redAccent, label: "Overtime"),
                //             ]
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 28),
              ],
            ),
          ),
    
      bottomNavigationBar: MyBottomNavBar(currentIndex: 0),
      
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final String? rightText;
  const _BigActionButton({required this.label, required this.color, required this.onPressed, this.rightText});
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: color.withAlpha((0.15 * 255).round()), blurRadius: 7, offset: const Offset(0,2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 3),
                child: Text(label,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ),
              if (rightText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(rightText!,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  const _SmallActionButton({required this.label, required this.color, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: color.withAlpha((0.12 * 255).round()), blurRadius: 5, offset: const Offset(0,2))],
          ),
          alignment: Alignment.center,
          child: Text(label,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// class _LegendItem extends StatelessWidget {
//   final Color color;
//   final String label;
//   const _LegendItem({required this.color, required this.label});
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(width:14, height:14, decoration:BoxDecoration(color: color, shape: BoxShape.circle)),
//         const SizedBox(width:5),
//         Text(label, style: GoogleFonts.nunito(fontSize: 12)),
//       ],
//     );
//   }
// }