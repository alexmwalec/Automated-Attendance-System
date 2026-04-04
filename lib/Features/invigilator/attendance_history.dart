import 'package:flutter/material.dart';

class AttendanceHistory extends StatelessWidget {
  const AttendanceHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
      ),
      body: const Center(
        child: Text(
          "Attendance History Screen 📊",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}