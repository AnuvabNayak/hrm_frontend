import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle_rounded, size: 100, color: Colors.blue),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/login?role=admin'),
              child: Text("Admin"),
            ),
            SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => context.go('/login?role=employee'),
              child: Text("Employee"),
            ),
          ],
        ),
      ),
    );
  }
}
