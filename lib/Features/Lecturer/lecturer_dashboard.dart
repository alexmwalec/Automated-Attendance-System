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
        title: const Text('AAS Lecturer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Profile())),
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(radius: 16, backgroundColor: tealDark, child: Icon(Icons.person, size: 20, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 2 || i == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => i == 2 ? const AttendanceHistory() : const Assign()));
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
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Assign'),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatefulWidget {
  const _DashboardPage();
  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> dynamicSessions = [];
  int courseCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      var lectDoc = await FirebaseFirestore.instance.collection('lecturers').doc(uid).get();
      if (!lectDoc.exists) { setState(() => isLoading = false); return; }

      List<dynamic> rawList = lectDoc.data()?['assignedCourses'] ?? [];
      List<String> codes = [];
      for (var item in rawList) {
        String val = item.toString();
        val.contains(',') ? codes.addAll(val.split(',').map((e) => e.trim())) : codes.add(val.trim());
      }

      List<Map<String, dynamic>> sessions = [];
      for (String code in codes) {
        if (code.isEmpty) continue;
        var courseDoc = await FirebaseFirestore.instance.collection('courses').doc(code).get();
        if (courseDoc.exists) {
          var d = courseDoc.data()!;
          sessions.add({'type': d['type'] ?? 'Class', 'course': code, 'date': d['date'] ?? 'Today', 'time': d['time'] ?? '--', 'room': d['room'] ?? 'TBA'});
        }
      }
      setState(() { dynamicSessions = sessions; courseCount = codes.length; isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: tealPrimary));
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            const _WelcomeCard(),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _InfoCard(icon: Icons.menu_book, title: 'Assigned', subtitle: '$courseCount Courses')),
              const SizedBox(width: 10),
              Expanded(child: _InfoCard(icon: Icons.event, title: 'Today', subtitle: '${dynamicSessions.length} Sessions')),
            ]),
            const SizedBox(height: 18),
            _TodaysSessionsTable(sessions: dynamicSessions),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: tealPrimary.withOpacity(0.2))),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Welcome Back!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealPrimary)),
      Text('Monitor your courses and student attendance records.', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _InfoCard({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: tealPrimary.withOpacity(0.1))),
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
    if (sessions.isEmpty) return const Center(child: Text("No courses assigned."));
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: tealPrimary.withOpacity(0.3)), color: Colors.white),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(color: tealPrimary, padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: ['TYPE', 'COURSE', 'DATE', 'TIME', 'ROOM'].map((h) => Expanded(child: Center(child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))))).toList())),
        ...sessions.asMap().entries.map((e) => Container(
          color: e.key.isEven ? Colors.white : tealLight.withOpacity(0.3), padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Expanded(child: Center(child: Text(e.value['type'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tealPrimary)))),
            Expanded(child: Center(child: Text(e.value['course'], style: const TextStyle(fontSize: 10)))),
            Expanded(child: Center(child: Text(e.value['date'], style: const TextStyle(fontSize: 10)))),
            Expanded(child: Center(child: Text(e.value['time'], style: const TextStyle(fontSize: 10)))),
            Expanded(child: Center(child: Text(e.value['room'], style: const TextStyle(fontSize: 10)))),
          ]),
        ))
      ]),
    );
  }
}