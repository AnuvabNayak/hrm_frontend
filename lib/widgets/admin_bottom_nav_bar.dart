import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const AdminBottomNavBar({required this.currentIndex, Key? key}) : super(key: key);

  static const List<String> routes = [
    '/admin/home',
    '/admin/employees',
    '/admin/attendance',
    '/admin/leaves',
    '/admin/posts',
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.red.shade600, // Different color for admin
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        context.go(routes[index]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "DASHBOARD"),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "EMPLOYEES"),
        BottomNavigationBarItem(icon: Icon(Icons.access_time), label: "ATTENDANCE"),
        BottomNavigationBarItem(icon: Icon(Icons.event_available), label: "LEAVES"),
        BottomNavigationBarItem(icon: Icon(Icons.campaign), label: "POSTS"),
      ],
    );
  }
}
