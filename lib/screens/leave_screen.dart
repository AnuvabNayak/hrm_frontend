import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
// import '../widgets/bottom_nav_bar.dart';
import '../services/leave_service.dart';
import '../models/leave_models.dart';
import '../utils/datetime_utils.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({Key? key}) : super(key: key);
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> with SingleTickerProviderStateMixin {
  // final _storage = const FlutterSecureStorage();
  late TabController _tabs;
  List<LeaveRequest> _requests = [];
  LeaveBalance? _balance;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        LeaveService.fetchLeaveRequests(),
        LeaveService.fetchLeaveBalance(),
      ]);
      if (!mounted) return;
      setState(() {
        _requests = (results[0] as List<LeaveRequest>?) ?? [];
        _balance = results[1] as LeaveBalance?;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/menu'),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Leave', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.black)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Leave Balance')],
        ),
      ),
      body: Column(children: [
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _overview(),
              _balanceTab(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.push('/leaves/request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Request for Leave', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ]),
      // bottomNavigationBar: const MyBottomNavBar(currentIndex: 4),
    );
  }

  Widget _overview() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, color: Colors.grey.shade400, size: 64),
          const SizedBox(height: 8),
          Text(_error!, style: GoogleFonts.nunito(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
        ]),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.event_available_outlined, color: Colors.grey.shade400, size: 64),
          const SizedBox(height: 8),
          Text('No leave requests yet', style: GoogleFonts.nunito(color: Colors.grey.shade600)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (ctx, i) => _requestCard(_requests[i]),
      ),
    );
  }

  Widget _requestCard(LeaveRequest r) {
    Color c; Color bg; IconData icon;
    switch (r.status) {
      case 'pending': c = Colors.orange.shade700; bg = Colors.orange.shade50; icon = Icons.schedule; break;
      case 'approved': c = Colors.green.shade700; bg = Colors.green.shade50; icon = Icons.check_circle; break;
      case 'denied': c = Colors.red.shade700; bg = Colors.red.shade50; icon = Icons.cancel; break;
      default: c = Colors.grey.shade700; bg = Colors.grey.shade50; icon = Icons.help;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: c, size: 14),
              const SizedBox(width: 4),
              Text(r.statusDisplay, style: GoogleFonts.nunito(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
          Text('${r.durationInDays} day${r.durationInDays > 1 ? 's' : ''}', style: GoogleFonts.nunito(color: Colors.grey.shade700)),
        ]),
        const SizedBox(height: 8),
        Text(r.dateRangeDisplay, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(r.leaveType, style: GoogleFonts.nunito(color: Colors.grey.shade600)),
        if (r.reason != null && r.reason!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.reason!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }

  Widget _balanceTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: GoogleFonts.nunito(color: Colors.grey.shade600)));
    }
    if (_balance == null) return Center(child: Text('No balance data', style: GoogleFonts.nunito(color: Colors.grey.shade600)));

    final b = _balance!;
    return RefreshIndicator(
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade400]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Available Leave Balance', style: GoogleFonts.nunito(color: Colors.white70)),
              const SizedBox(height: 6),
              Row(children: [
                Text('${b.availableCoins}', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36)),
                const SizedBox(width: 6),
                Text('days', style: GoogleFonts.nunito(color: Colors.white70)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          if (b.expiringSoon.isNotEmpty) ...[
            Text('Expiring Soon', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...b.expiringSoon.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
              child: Row(children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${e.amount} day${e.amount > 1 ? 's' : ''} expiring', style: GoogleFonts.nunito(color: Colors.orange.shade800, fontWeight: FontWeight.w700)),
                  Text('Expires on ${DateTimeUtils.formatDisplayDate(e.expiryDate)}', style: GoogleFonts.nunito(color: Colors.orange.shade700)),
                ])),
                Text('${e.daysUntilExpiry} days left', style: GoogleFonts.nunito(color: Colors.orange.shade700, fontWeight: FontWeight.w700)),
              ]),
            )),
            const SizedBox(height: 16),
          ],
          if (b.recentTransactions.isNotEmpty) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Recent Activity', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              Text('Last 10 transactions', style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            ...b.recentTransactions.map((t) {
              Color c; IconData i;
              switch (t.type) {
                case 'grant': c = Colors.green.shade600; i = Icons.add_circle_outline; break;
                case 'consume': c = Colors.blue.shade600; i = Icons.remove_circle_outline; break;
                case 'expire': c = Colors.red.shade600; i = Icons.schedule; break;
                default: c = Colors.grey.shade600; i = Icons.swap_horiz;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: Row(children: [
                  Icon(i, color: c),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.typeDisplay, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    Text(DateTimeUtils.formatDisplayDate(t.occurredAt), style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 12)),
                    if (t.comment != null && t.comment!.isNotEmpty)
                      Text(t.comment!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 11)),
                  ])),
                  Text(t.amountDisplay, style: GoogleFonts.nunito(color: c, fontWeight: FontWeight.bold)),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }
}
