import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'select_course.dart';
import 'assign.dart';
import 'attendance_history.dart';
import 'profile.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class LecturerDashboard extends StatefulWidget {
  final int initialIndex;
  const LecturerDashboard({super.key, this.initialIndex = 0});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const _DashboardPage(),
    const CourseSelectionScreen(),
    const AttendanceHistory(),
    const Assign(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('AAS Lecturer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Profile())),
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                  radius: 16,
                  backgroundColor: tealDark,
                  child: Icon(Icons.person, size: 20, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 2 || i == 3) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => i == 2 ? const AttendanceHistory() : const Assign()));
          } else {
            setState(() => _currentIndex = i);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'Manage'),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('active_sessions')
          .where('lecturerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        int activeCount = 0;
        List<Map<String, dynamic>> sessions = [];

        if (snapshot.hasData) {
          activeCount = snapshot.data!.docs.length;
          sessions = snapshot.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return {
              'type': d['sessionType'] ?? 'N/A',
              'course': d['courseCode'] ?? 'N/A',
              'date': 'Today',
              'time': d['startTime'] ?? '--',
              'room': 'TBA'
            };
          }).toList();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              const _WelcomeCard(),
              const SizedBox(height: 14),
              Row(children: [
                const Expanded(
                    child: _InfoCard(
                        icon: Icons.menu_book, title: 'Status', subtitle: 'Active Mode')),
                const SizedBox(width: 10),
                Expanded(
                    child: _InfoCard(
                        icon: Icons.event, title: 'Today', subtitle: '$activeCount Sessions')),
              ]),
              const SizedBox(height: 18),
              _TodaysSessionsTable(sessions: sessions),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tealPrimary.withOpacity(0.2))),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Welcome Back!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealPrimary)),
      Text('Your active sessions are shown below.',
          style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoCard({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tealPrimary.withOpacity(0.1))),
    child: Row(children: [
      Icon(icon, color: tealPrimary, size: 20),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: tealDark)),
      ])
    ]),
  );
}

class _TodaysSessionsTable extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  const _TodaysSessionsTable({required this.sessions});
  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tealPrimary.withOpacity(0.1))),
        child: const Center(
            child: Text("No active sessions created.",
                style: TextStyle(color: Colors.grey, fontSize: 12))),
      );
    }
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tealPrimary.withOpacity(0.3)),
          color: Colors.white),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
            color: tealPrimary,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
                children: ['TYPE', 'COURSE', 'DATE', 'TIME']
                    .map((h) => Expanded(
                    child: Center(
                        child: Text(h,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)))))
                    .toList())),
        ...(sessions ?? []).asMap().entries.map((e) => Container(
          color: e.key.isEven ? Colors.white : tealLight.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Expanded(
                child: Center(
                    child: Text(e.value['type'],
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold, color: tealPrimary)))),
            Expanded(child: Center(child: Text(e.value['course'], style: const TextStyle(fontSize: 10)))),
            Expanded(child: Center(child: Text(e.value['date'], style: const TextStyle(fontSize: 10)))),
            Expanded(child: Center(child: Text(e.value['time'], style: const TextStyle(fontSize: 10)))),
          ]),
        ))
      ]),
    );
  }
}