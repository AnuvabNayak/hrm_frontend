import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/leave_service.dart';
import '../models/leave_models.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';
import '../utils/datetime_utils.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({Key? key}) : super(key: key);
  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _storage = const FlutterSecureStorage();

  ProfileModel? _profile;
  String _policy = 'Vacation Leave';
  bool _fullDay = true;
  DateTime? _start;
  DateTime? _end;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final jwt = await _storage.read(key: 'jwt');
    if (jwt == null) return;
    final p = await ProfileService.fetchProfile(jwt);
    if (mounted) setState(() => _profile = p);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final init = start
        ? (_start ?? DateTime.now().add(const Duration(days: 1)))
        : (_end ?? _start ?? DateTime.now().add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.blue.shade600,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end != null && _end!.isBefore(_start!)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_start == null) {
      setState(() => _error = 'Please select start date');
      return;
    }
    if (!_fullDay && _end == null) {
      setState(() => _error = 'Please select end date');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final payload = LeaveRequestCreate(
      startDate: _start!,
      endDate: _fullDay ? _start! : _end!,
      leaveType: _policy,
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
    );

    final days = (_fullDay ? 1 : _end!.difference(_start!).inDays + 1);
    final balance = await LeaveService.fetchLeaveBalance();
    if (balance != null && balance.availableCoins < days) {
      setState(() => _error = 'Insufficient leave balance. Available: ${balance.availableCoins}, needed: $days.');
      return;
    }

    final err = await LeaveService.createLeaveRequest(payload);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Leave request submitted!'),
        backgroundColor: Colors.green,
      ));
      context.pop();
      return;
    }
    setState(() => _error = err);
  }

  int get _days {
    if (_start == null) return 0;
    if (_fullDay) return 1;
    if (_end == null) return 0;
    return _end!.difference(_start!).inDays + 1;
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
        title: Text(
          'Leave Request',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_profile != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Requesting as ${_profile!.displayName}',
                          style: GoogleFonts.nunito(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),

                    _tile(
                      icon: Icons.policy_outlined,
                      title: 'Select a Policy',
                      trailing: Text(_policy, style: GoogleFonts.nunito(color: Colors.grey.shade600)),
                      onTap: _choosePolicy,
                    ),
                    const SizedBox(height: 20),

                    _tile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Full day',
                      trailing: Switch(
                        value: _fullDay,
                        onChanged: (v) => setState(() => _fullDay = v),
                        activeColor: Colors.blue.shade600,
                      ),
                      onTap: () => setState(() => _fullDay = !_fullDay),
                    ),
                    const SizedBox(height: 20),

                    _tile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Start date',
                      trailing: _dateTrailing(_start),
                      onTap: () => _pickDate(true),
                    ),
                    if (!_fullDay) ...[
                      const SizedBox(height: 20),
                      _tile(
                        icon: Icons.calendar_today_outlined,
                        title: 'End date',
                        trailing: _dateTrailing(_end),
                        onTap: () => _pickDate(false),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _reasonTile(),
                    const SizedBox(height: 20),

                    if (_start != null) _summaryCard(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _errorBox(_error!),
                    ],
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('Request', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _tile({required IconData icon, required String title, required VoidCallback onTap, required Widget trailing}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w600))),
          trailing,
        ]),
      ),
    );
  }

  Widget _reasonTile() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 12), child: Icon(Icons.notes_outlined, color: Colors.grey.shade600)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add a reason or note', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reason,
              maxLines: 3,
              decoration: InputDecoration(hintText: 'Enter reason...', border: InputBorder.none),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _dateTrailing(DateTime? dt) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(dt != null ? DateTimeUtils.formatDisplayDate(dt) : '', style: GoogleFonts.nunito(color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ]);

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Request Summary', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
        const SizedBox(height: 8),
        Text('Duration: $_days day${_days > 1 ? 's' : ''}', style: GoogleFonts.nunito(color: Colors.blue.shade700)),
        if (_days > 0) ...[
          const SizedBox(height: 4),
          Text(
            _fullDay ? DateTimeUtils.formatDisplayDate(_start) : '${DateTimeUtils.formatDisplayDate(_start)} - ${DateTimeUtils.formatDisplayDate(_end)}',
            style: GoogleFonts.nunito(color: Colors.blue.shade700),
          )
        ]
      ]),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: GoogleFonts.nunito(color: Colors.red.shade700))),
      ]),
    );
  }

  void _choosePolicy() {
    final policies = [
      'Vacation Leave',
      'Sick Leave',
      'Personal Leave',
      'Emergency Leave',
      'Maternity Leave',
      'Paternity Leave',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Leave Policy', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...policies.map((p) => ListTile(
                title: Text(p, style: GoogleFonts.nunito()),
                trailing: _policy == p ? Icon(Icons.check, color: Colors.blue.shade600) : null,
                onTap: () {
                  setState(() => _policy = p);
                  Navigator.pop(context);
                },
              )),
        ]),
      ),
    );
  }
}
