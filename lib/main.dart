import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/timesheet_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/company_details_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/admin_posts_screen.dart';
import 'screens/admin_create_post_screen.dart';

import 'screens/menu_screen.dart';
import 'screens/leave_process_screen.dart';
import 'screens/leave_screen.dart';
import 'screens/leave_request_screen.dart';
import 'screens/admin_home_screen.dart';
import 'services/role_service.dart';

import 'screens/admin_attendance_screen.dart';
import 'screens/admin_employee_attendance_detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'models/profile_model.dart';

import 'screens/admin_leave_approval_screen.dart';
import 'screens/admin_employee_management_screen.dart';
import 'screens/admin_create_employee_screen.dart';
import 'screens/admin_edit_employee_screen.dart';


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
      path: '/profile/edit',
      name: 'edit-profile',
      builder: (context, state) {
        final profile = state.extra as ProfileModel;
        return EditProfileScreen(profile: profile);
      },
    ),
    GoRoute(
      path: '/company-details',
      name: 'company-details',
      builder: (context, state) => const CompanyDetailsScreen(),
    ),
    GoRoute(
      path: '/posts',
      name: 'posts',
      builder: (context, state) => const PostsScreen(),
    ),
    GoRoute(
      path: '/admin/posts',
      name: 'admin-posts',
      builder: (context, state) => const AdminPostsScreen(),
    ),
    GoRoute(
      path: '/menu',
      name: 'menu',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/leaves',
      name: 'leaves',
      builder: (context, state) => const LeaveScreen(),
    ),
    GoRoute(
      path: '/leaves/request',
      name: 'leave-request',
      builder: (context, state) => const LeaveRequestScreen(),
    ),
    GoRoute(
      path: '/leaves/process',
      name: 'leave-process',
      builder: (context, state) => const LeaveProcessScreen(),
    ),

    // ADMIN ROUTES
    GoRoute(
      path: '/admin/home',
      name: 'admin-home',
      builder: (context, state) => const AdminHomeScreen(),
    ),
    // Admin Employee Management (replaces placeholder)
    GoRoute(
      path: '/admin/employees',
      name: 'admin-employees',
      builder: (context, state) => const AdminEmployeeManagementScreen(),
    ),
    // Admin Employee Creation
    GoRoute(
      path: '/admin/employees/create',
      name: 'admin-create-employee',
      builder: (context, state) => const AdminCreateEmployeeScreen(),
    ),
    // Admin Employee Edit
    GoRoute(
      path: '/admin/employees/:employeeId/edit',
      name: 'admin-edit-employee',
      builder: (context, state) {
        final employeeId = state.pathParameters['employeeId']!;
        return AdminEditEmployeeScreen(employeeId: employeeId);
      },
    ),
    // Admin Leave Approval (replaces placeholder)
    GoRoute(
      path: '/admin/leaves',
      name: 'admin-leaves',
      builder: (context, state) => const AdminLeaveApprovalScreen(),
    ),
    GoRoute(
      path: '/admin/create-post',
      builder: (context, state) => const AdminCreatePostScreen(),
    ),
    GoRoute(
      path: '/admin/attendance',
      name: 'admin-attendance',
      builder: (context, state) => const AdminAttendanceScreen(),
    ),
    GoRoute(
      path: '/admin/employee/:employeeId/attendance',
      name: 'admin-employee-attendance-detail',
      builder: (context, state) {
        final employeeId = state.pathParameters['employeeId']!;
        return AdminEmployeeAttendanceDetailScreen(employeeId: employeeId);
      },
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
    );
  }
}
