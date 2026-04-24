import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'Features/Lecturer/profile.dart';
import 'Features/Lecturer/select_course.dart';
import 'Features/Lecturer/attendance_history.dart';
import 'Features/Lecturer/report.dart';
import 'Features/Lecturer/take_attendance.dart';
import 'Features/Lecturer/lecturer_dashboard.dart';
import 'Features/Invigilator/invigilator_dashboard.dart'; // Added this
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(const AttendanceApp());
  } catch (e) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Firebase Error: $e")))));
  }
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
       
        primaryColor: const Color(0xFF2E9E8E),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E9E8E)),
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const LoginScreen(),
        "/lecturer_dashboard": (context) => const LecturerDashboard(), // for lecturer
        "/invigilator_dashboard": (context) => const InvigilatorDashboard(), // for invigilator
        "/scanner": (context) => const AttendancePage(),
        "/profile": (context) => const Profile(),
        "/course": (context) => const Course(),
        "/report": (context) => const Report(),
        "/attendance_history": (context) => const AttendanceHistory(),
      },
    );
  }
}