import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/auth_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();

  ProfileModel? profile;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAndSetProfile();
  }

  Future<void> fetchAndSetProfile() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final jwt = await _storage.read(key: "jwt");
      if (jwt == null) throw Exception("Not authorized. Please log in.");
      final prof = await ProfileService.fetchProfile(jwt);
      if (prof == null) {
        setState(() => error = "Could not load profile.");
      } else {
        setState(() => profile = prof);
      }
    } catch (e) {
      setState(() => error = "Error loading profile.");
    } finally {
      setState(() => loading = false);
    }
  }

  // ✅ Utility to validate avatar URL
  bool _isValidAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url == 'string') return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Personal Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: fetchAndSetProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchAndSetProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.06),
                      child: _buildProfileContent(context),
                    ),
                  ),
      ),
      bottomNavigationBar: MyBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildProfileContent(BuildContext context) {

    final name = profile?.name ?? '-';
    final employeeId =
        profile?.employeeId != null ? profile!.employeeId.toString() : '-';
    final email = profile?.displayEmail ?? 'Not available';
    final phone = profile?.displayPhone ?? 'Not available';
    final empCode = profile?.displayEmpCode ?? 'Not available';
    // final email = profile?.email ?? '-';
    // final phone = profile?.phone ?? '-';
    // final empCode = profile?.empCode ?? '-';

    return Center(
      child: Column(
        children: [
          // ✅ Updated CircleAvatar with validation
          CircleAvatar(
            radius: MediaQuery.of(context).size.width * 0.15,
            backgroundColor: Colors.blue.shade400,
            backgroundImage: _isValidAvatarUrl(profile?.avatarUrl)
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: !_isValidAvatarUrl(profile?.avatarUrl)
                ? Text(
                    (profile?.username != null &&
                            profile!.username!.isNotEmpty)
                        ? profile!.username![0].toUpperCase()
                        : (name.isNotEmpty ? name[0].toUpperCase() : "?"),
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          profileDetailRow('Name:', name),
          profileDetailRow('Employee ID:', employeeId),
          profileDetailRow('Emp Code:', empCode),
          profileDetailRow('Email:', email),
          profileDetailRow('Phone:', phone),

          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          SizedBox(
            width: 140,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Push to edit profile screen or open edit modal
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Edit'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          // TextButton(
          //   onPressed: () async {
          //     await AuthService.logout();
          //     setState(() {
          //       profile = null;
          //       loading = false;
          //       error = null;
          //     });
          //     // Navigate to login and clear history
          //     Navigator.of(context).pushNamedAndRemoveUntil(
          //       '/', // Go to splash screen, not directly to login
          //       (Route<dynamic> route) => false,
          //     );
          //   },
          //   child: const Text("Logout", style: TextStyle(color: Colors.red)),
          // ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              // Remove all routes and go to login screen
              context.goNamed('splash');
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget profileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ),
        ],
      ),
    );
  }
}
