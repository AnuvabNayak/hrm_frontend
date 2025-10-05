import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final int unreadCount; // ✅ ADD for notification badge

  const MyBottomNavBar({
    required this.currentIndex, 
    this.unreadCount = 0, // ✅ ADD
    Key? key
  }) : super(key: key);

  static const List<String> routes = [
    '/home',
    '/posts', // ✅ CHANGED from '/inbox'
    '/timesheet',
    '/profile',
    '/menu',
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
        context.go(routes[index]);
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: "HOME"),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.campaign), // ✅ CHANGED icon
              if (unreadCount > 0) // ✅ ADD notification badge
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: "POSTS", // ✅ CHANGED label
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.access_time), label: "TIMESHEET"),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: "PROFILE"),
        const BottomNavigationBarItem(icon: Icon(Icons.menu), label: "MENU"),
      ],
    );
  }
}
