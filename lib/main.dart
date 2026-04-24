import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'Features/Lecturer/profile.dart';
import 'Features/Lecturer/select_course.dart';
import 'Features/Lecturer/attendance_history.dart';
import 'Features/Lecturer/report.dart';
import 'Features/Lecturer/take_attendance.dart';
import 'Features/Lecturer/lecturer_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");


    runApp(const AttendanceApp());

  } catch (e) {
    print("Firebase failed to initialize: $e");

    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "CRITICAL CONFIG ERROR:\n\n$e\n\nEnsure you ran 'flutterfire configure' for this platform.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    ));
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