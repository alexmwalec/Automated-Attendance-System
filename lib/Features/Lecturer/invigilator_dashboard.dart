import 'package:flutter/material.dart';

class InvigilatorDashboard extends StatefulWidget {
  const InvigilatorDashboard({super.key});

  @override
  State<InvigilatorDashboard> createState() => _InvigilatorDashboardState();
}

class _InvigilatorDashboardState extends State<InvigilatorDashboard> {
  static const Color unimaPurple = Color(0xFF5D00D2);
  static const Color unimaGold = Color(0xFFC5A021);
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: unimaPurple,
        title: const Text('AAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSidebarVisible = !_isSidebarVisible;
            });
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.video_call, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey,
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
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Welcome Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: unimaGold.withOpacity(0.4),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(8),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.black, fontSize: 13),
                              children: [
                                TextSpan(text: 'Welcome to Automated Attendance System. This portal allows invigilators to record and manage examination attendance quickly and securely. Only authorized staff can access this system, and all attendance records are stored in the central database for official use. If you experience any problem while using the system, please contact the ICT Support Office or the Examinations Office for assistance.\n'),
                                TextSpan(
                                  text: 'Always remember to logout from the system when you are done.',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Notice Board Section
                  const Row(
                    children: [
                      Icon(Icons.campaign, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('NOTICE BOARD', style: TextStyle(color: unimaPurple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  // Info Cards
                  const InfoCard(
                    icon: Icons.calendar_today,
                    title: 'Assigned Exams',
                    subtitle: 'Exams Today : 2',
                    iconColor: Colors.blue,
                  ),
                  const InfoCard(
                    icon: Icons.location_on,
                    title: 'Exam Venue',
                    subtitle: 'CH 2',
                    iconColor: Colors.purple,
                  ),
                  const InfoCard(
                    icon: Icons.monitor,
                    title: 'System Status',
                    subtitle: 'Ready to take attendance',
                    iconColor: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/notice.png',
                      height: 150,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 150, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'General Notice',
                      style: TextStyle(color: unimaPurple, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const NoticeText(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String title, String route, {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? unimaPurple : Colors.black54),
      title: Text(title, style: TextStyle(color: isSelected ? unimaPurple : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        if (route != '#') Navigator.pushReplacementNamed(context, route);
      },
    );
  }

  Widget _buildExpandableSidebarItem(BuildContext context, IconData icon, String title, List<Map<String, String>> subItems) {
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

// InfoCard and NoticeText remain same as before
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const InfoCard({super.key, required this.icon, required this.title, required this.subtitle, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

class NoticeText extends StatelessWidget {
  const NoticeText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(color: Colors.black, fontSize: 13, height: 1.5),
        children: [
          TextSpan(text: 'Authorized Access Only\n', style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: '• ', style: TextStyle(color: Colors.red)),
          TextSpan(text: 'Invigilators ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          TextSpan(text: 'must use their official credentials. Sharing login details is '),
          TextSpan(text: 'strictly prohibited.\n', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          TextSpan(text: 'Correct Exam & Course Selection\n', style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: '• ', style: TextStyle(color: Colors.red)),
          TextSpan(text: 'Before ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          TextSpan(text: 'taking attendance, '),
          TextSpan(text: 'confirm ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          TextSpan(text: 'the correct exam and course are selected.\n'),
          TextSpan(text: 'Accurate Attendance Recording\n', style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: '• ', style: TextStyle(color: Colors.red)),
          TextSpan(text: 'Scan each ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          TextSpan(text: 'student ID carefully. Ensure all students present are recorded in the system.\n'),
          TextSpan(text: '• Any discrepancies must be reported immediately to the Exams Office'),
        ],
      ),
    );
  }
}