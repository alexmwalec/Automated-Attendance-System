import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'invigilator_home.dart';
import 'invigilator_attendance_list.dart';

class InvigilatorDashboard extends StatefulWidget {
  const InvigilatorDashboard({super.key});

  @override
  State<InvigilatorDashboard> createState() => _InvigilatorDashboardState();
}

class _InvigilatorDashboardState extends State<InvigilatorDashboard> {
  int _currentIndex = 0;

  static const Color tealPrimary = Color(0xFF2E9E8E);

  final List<Widget> _pages = const [
    InvigilatorHome(),
    InvigilatorAttendanceList(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
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
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}
