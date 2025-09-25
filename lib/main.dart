import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/timesheet_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/company_details_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/leave_process_screen.dart';

final GoRouter _router = GoRouter(
  // initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final role = state.uri.queryParameters['role'];
        return LoginScreen(role: role);
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/timesheet',
      name: 'timesheet',
      builder: (context, state) => const TimesheetScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/menu',
      name: 'menu',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/inbox',
      name: 'inbox', 
      builder: (context, state) => const InboxScreen(),
    ),
    GoRoute(
      path: '/company-details',
      name: 'company-details',
      builder: (context, state) => const CompanyDetailsScreen(),
    ),
    GoRoute(
      path: '/leave-process',
      name: 'leave-process',
      builder: (context, state) => const LeaveProcessScreen(),
      ),
    ],
  );

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Zytexa HRM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Nunito', // use your Google Font as in Figma
      ),
      debugShowCheckedModeBanner: false,
      // routes: {
      //   '/login': (context) => LoginScreen(),
      //   '/home': (context) => HomeScreen(),
      //   '/profile': (context) => ProfileScreen(),
      //   // other routes...
      // },
    );
  }
}
