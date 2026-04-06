import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const Color unimaPurple = Color(0xFF5D00D2);
  static const Color unimaGold = Color(0xFFC5A021);
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: unimaPurple,
        title: const Text('AAS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSidebarVisible = !_isSidebarVisible;
            });
          },
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
      body: Row(
        children: [
          // Sidebar
          if (_isSidebarVisible)
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(
                      color: Colors.blue.shade100.withOpacity(0.5), width: 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          size: 100, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'MAIN NAVIGATION MENU',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildSidebarItem(context, Icons.stars_outlined,
                            'Dashboard', '/dashboard'),
                        _buildSidebarItem(context, Icons.person_outline,
                            'Profile', '/profile'),
                        _buildExpandableSidebarItem(
                            context, Icons.edit_note, 'Take Attendance', [
                          {'title': 'Exam Attendance', 'route': '/scanner'},
                          {'title': 'Class Attendance', 'route': '/scanner'},
                          {'title': 'Lab Attendance', 'route': '/scanner'},
                        ]),
                        _buildSidebarItem(
                            context,
                            Icons.assignment_turned_in_outlined,
                            'Assign Invigilator',
                            '#'),
                        _buildSidebarItem(context, Icons.analytics_outlined,
                            'Analytics', '#'),
                        _buildSidebarItem(context, Icons.history,
                            'Attendance History', '/attendance_history'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: unimaGold,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attendance',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                                color: Colors.white)),
                        SizedBox(height: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Attendance scanner will go here...",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar Helper Methods
  Widget _buildSidebarItem(
      BuildContext context, IconData icon, String title, String route,
      {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? unimaPurple : Colors.black54),
      title: Text(title,
          style: TextStyle(
              color: isSelected ? unimaPurple : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        if (route != '#' && route != ModalRoute.of(context)?.settings.name) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildExpandableSidebarItem(BuildContext context, IconData icon,
      String title, List<Map<String, String>> subItems) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      children: subItems.map((item) {
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 70),
          title: Text(item['title']!, style: const TextStyle(fontSize: 13)),
          onTap: () => Navigator.pushReplacementNamed(context, item['route']!),
        );
      }).toList(),
    );
  }
}