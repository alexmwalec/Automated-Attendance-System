import 'package:flutter/material.dart';

class InvigilatorDashboard extends StatelessWidget {
  const InvigilatorDashboard({super.key});

  static const Color unimaPurple = Color(0xFF5D00D2);
  static const Color unimaGold = Color(0xFFC5A021);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: unimaPurple,
        title: const Text('AAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
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
            // Notice Image updated to use local asset
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
    );
  }
}
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const SizedBox(height: 40),

          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person, size: 50, color: Colors.grey),
          ),

          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'MAIN NAVIGATION MENU',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          DrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/dashboard',
          ),

          DrawerItem(
            icon: Icons.qr_code_scanner,
            title: 'Take Attendance',
            route: '/scanner',
          ),

          DrawerItem(
            icon: Icons.person_outline,
            title: 'Profile',
            route: '/profile',
          ),

          DrawerItem(
            icon: Icons.assignment_outlined,
            title: 'Select Course',
            route: '/course',
          ),

          DrawerItem(
            icon: Icons.edit_note,
            title: 'Write Report',
            route: '/report',
          ),

          DrawerItem(
            icon: Icons.history,
            title: 'Attendance History',
            route: '/attendance_history',
          ),
        ],
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // close drawer
        Navigator.pushReplacementNamed(context, route); // navigate
      },
    );
  }
}
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
