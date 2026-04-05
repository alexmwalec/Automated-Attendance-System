import 'package:flutter/material.dart';
import 'package:automated_attendance_system/Features/Lecturer/invigilator_dashboard.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D00D2), // unima Purple colour
        title: const Text('AAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.green,
              radius: 15,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A021), // unima Gold colour
                border: Border.all(color: Colors.grey.shade400),

              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 19, color: Colors.white)),
                  const SizedBox(height:6),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("Attendance scanner will go here...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      ),
    );
  }
}