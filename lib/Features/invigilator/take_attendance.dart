import 'package:flutter/material.dart';

class TakeAttendance extends StatelessWidget {
  const TakeAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Take Attendance"),
      ),
      body: const Center(
        child: Text(
          "QR Scanner Coming Soon",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}