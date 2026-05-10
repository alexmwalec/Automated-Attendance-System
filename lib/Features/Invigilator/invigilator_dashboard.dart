import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invigilator_home.dart';
import 'invigilator_take_attendance.dart';
import 'invigilator_attendance_list.dart';
import 'invigilator_report.dart';

class InvigilatorDashboard extends StatefulWidget {
  const InvigilatorDashboard({super.key});

  @override
  State<InvigilatorDashboard> createState() => _InvigilatorDashboardState();
}

class _InvigilatorDashboardState extends State<InvigilatorDashboard> {
  int _currentIndex = 0;

  static const Color tealPrimary = Color(0xFF2E9E8E);

  @override
  Widget build(BuildContext context) {
    // Fetch the assignment once at dashboard level so all tabs share the data
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exam_assignments')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        // Extract assignment details — default to empty strings if not yet available
        String courseCode = '';
        String date = '';
        String venue = '';

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          courseCode = data['course'] ?? '';
          date = data['date'] ?? '';
          venue = data['room'] ?? '';
        }

        // Build pages with the live assignment data passed in
        final List<Widget> pages = [
          const InvigilatorHome(),
          const InvigilatorTakeAttendance(),
          const InvigilatorAttendanceList(),
          InvigilatorReport(
            courseCode: courseCode,
            date: date,
            venue: venue,
          ),
        ];

        return Scaffold(
          body: pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: tealPrimary,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white60,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                activeIcon: Icon(Icons.qr_code_scanner),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'Attendance List',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit_document),
                activeIcon: Icon(Icons.edit_document),
                label: 'Report',
              ),
            ],
          ),
        );
      },
    );
  }
}
