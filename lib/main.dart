
import 'package:flutter/material.dart';
import 'login_screen.dart';

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
          primary: const Color(0xFF5D00D2),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
