import 'package:flutter/material.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  // Profile Avatar
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
                        _buildSidebarItem(
                            context, Icons.stars_outlined, 'Dashboard', '/dashboard'),
                        _buildSidebarItem(
                            context, Icons.person_outline, 'Profile', '/profile'),
                        _buildExpandableSidebarItem(
                            context, Icons.edit_note, 'Take Attendance', [
                          {'title': 'Exam Attendance', 'route': '/scanner'},
                          {'title': 'Class Attendance', 'route': '/scanner'},
                          {'title': 'Lab Attendance', 'route': '/scanner'},
                        ]),
                        _buildSidebarItem(context,
                            Icons.assignment_turned_in_outlined, 'Assign Invigilator', '#'),
                        _buildSidebarItem(
                            context, Icons.analytics_outlined, 'Analytics', '#'),
                        _buildSidebarItem(context, Icons.history, 'Attendance History',
                            '/attendance_history',
                            isSelected: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Navbar
                Container(
                  height: 80,
                  color: const Color(0xFF0000FF), // Bright Blue
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSidebarVisible = !_isSidebarVisible;
                          });
                        },
                        icon: Icon(
                            _isSidebarVisible ? Icons.menu_open : Icons.menu,
                            color: Colors.white,
                            size: 28),
                      ),
                      const SizedBox(width: 15),
                      // Logo Placeholder
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/unima_logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.school, color: Colors.blue, size: 25),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        'AAM SYSTEM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.notifications_none,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 20),
                      PopupMenuButton<String>(
                        tooltip: '',
                        onSelected: (value) {
                          if (value == 'logout') {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        constraints: const BoxConstraints(minWidth: 120),
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'logout',
                            height: 35,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.black54, size: 20),
                                SizedBox(width: 8),
                                Text('Logout', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: Colors.grey, size: 28),
                            ),
                            SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KINGSLEY NASIMBA',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                                Text(
                                  'LECTURER',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // History Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 15),
                          color: const Color(0xFFC5A021).withOpacity(0.6), // Muted Gold
                          child: const Row(
                            children: [
                              Icon(Icons.history, size: 24),
                              SizedBox(width: 15),
                              Text(
                                'Attendance History',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Stats Cards
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Total Sessions 128')),
                            const SizedBox(width: 20),
                            Expanded(child: _buildStatCard('Class Sessions 79')),
                            const SizedBox(width: 20),
                            Expanded(child: _buildStatCard('Lab Sessions 80')),
                            const SizedBox(width: 20),
                            Expanded(child: _buildStatCard('Exam Sessiosn 40')),
                          ],
                        ),
                        const SizedBox(height: 40),

                        const SizedBox(height: 40),

                        // Table
                        const Divider(color: Color(0xFF1A237E), thickness: 2),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: Text('DATE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(
                                  flex: 3,
                                  child: Text('COURSE',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(
                                  flex: 3,
                                  child: Text('TYPE',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(
                                  flex: 2,
                                  child: Text('YEAR',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(
                                  flex: 3,
                                  child: Text('PRESENT',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(
                                  flex: 3,
                                  child: Text('ABSENT',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(
                                  flex: 3,
                                  child: Text('ACTION',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDataRow('14 may', 'com411', 'Class', '4', '40', '0'),
                        _buildDataRow('14 may', 'com411', 'Exam', '1', '70', '4'),
                        _buildDataRow('14 may', 'com411', 'Exam', '3', '70', '4'),
                        _buildDataRow('14 may', 'com411', 'Lab', '2', '70', '20'),

                        const SizedBox(height: 60),

                        // Bottom Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton('Generate report'),
                            const SizedBox(width: 40),
                            _buildActionButton('Downloaod'),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
      BuildContext context, IconData icon, String title, String route,
      {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        if (route != '#' && ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildExpandableSidebarItem(BuildContext context, IconData icon,
      String title, List<Map<String, String>> subItems) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.black, size: 24),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      ),
      children: subItems
          .map((sub) => Padding(
                padding: const EdgeInsets.only(left: 50.0),
                child: ListTile(
                  title: Text(sub['title']!, style: const TextStyle(fontSize: 13)),
                  onTap: () {
                    if (sub['route'] != '#') {
                      Navigator.pushReplacementNamed(context, sub['route']!);
                    }
                  },
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStatCard(String text) {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Color(0xFFE3F2FD),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildDataRow(String date, String course, String type, String year,
      String present, String absent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(date, style: const TextStyle(fontSize: 14))),
          Expanded(
              flex: 3,
              child: Text(course,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
          Expanded(
              flex: 3,
              child: Text(type,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
          Expanded(
              flex: 2,
              child: Text(year,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
          Expanded(
              flex: 3,
              child: Text(present,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
          Expanded(
              flex: 3,
              child: Text(absent,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
          Expanded(
            flex: 3,
            child: Center(
              child: SizedBox(
                width: 75,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0000FF),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 13)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text) {
    return SizedBox(
      width: 140,
      height: 40,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0000FF),
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}
