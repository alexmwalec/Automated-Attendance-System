import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'Features/Lecturer/profile.dart';
import 'Features/Lecturer/select_course.dart';
import 'Features/Lecturer/attendance_history.dart';
import 'Features/Lecturer/report.dart';
import 'Features/Lecturer/take_attendance.dart';
import 'Features/Lecturer/invigilator_dashboard.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF5D00D2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D00D2),
        ),
      ),

      initialRoute: "/",

      routes: {
        "/": (context) => const LoginScreen(),
        "/dashboard": (context) => const InvigilatorDashboard(),
        "/scanner": (context) => const AttendancePage(),
        "/profile": (context) => const Profile(),
        "/course": (context) => const Course(),
        "/report": (context) => const Report(),
        "/attendance_history": (context) => const AttendanceHistory(),
      },
    );
  }
}