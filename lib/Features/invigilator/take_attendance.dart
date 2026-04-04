import 'package:flutter/material.dart';
import 'package:automated_attendance_system/Features/invigilator/invigilator_dashboard.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D00D2), // unimaPurple colour
        title: const Text('AAS', style: TextStyle(color: Colors.white, fontWeight:FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions:[
          IconButton(icon:  const Icon(Icons.notifications_none,color: Colors.white,), onPressed: (){},
          ),
          const Padding(padding: EdgeInsets.only(right: 16.0),
           child: CircleAvatar(
             backgroundColor: Colors.green,
             radius: 15,
           ),
          ),
        ],
      ),

      drawer: const AppDrawer(),
      body: const Center(
        child: Text("Your Attendance Scanner Logic Goes Here"),
      ),
    );
  }
}