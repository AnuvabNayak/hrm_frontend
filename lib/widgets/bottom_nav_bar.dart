// lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const MyBottomNavBar({required this.currentIndex, Key? key}) : super(key: key);

  static const List<String> routes = [
    '/home',
    '/inbox',   // Add Inbox screen and route if/when you implement it
    '/timesheet',
    '/profile',
    '/menu',    // Add Menu screen and route if/when you implement it
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        // Use GoRouter navigation, NOT Navigator!
        context.go(routes[index]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "HOME"),
        BottomNavigationBarItem(icon: Icon(Icons.mail), label: "INBOX"),
        BottomNavigationBarItem(icon: Icon(Icons.access_time), label: "TIMESHEET"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "PROFILE"),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: "MENU"),
      ],
    );
  }
}
