import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'select_course.dart';
import 'assign.dart';
import 'attendance_history.dart';

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

  // Only 2 inline pages; History and Assign are pushed
  final List<Widget> _pages = [
    const _DashboardPage(),
    const CourseSelectionScreen(),
  ];

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('AAS Lecturer',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
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
                    builder: (_) =>
                        i == 2 ? const AttendanceHistory() : const Assign()));
          } else {
            setState(() => _currentIndex = i);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Attendance'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined), label: 'Manage'),
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isSessionLive(String startTimeStr, String endTimeStr) {
    try {
      final now = DateTime.now();
      final start = _parseTime(startTimeStr);
      TimeOfDay end;

      if (endTimeStr == '--' || endTimeStr.isEmpty) {
        end = TimeOfDay(hour: (start.hour + 2) % 24, minute: start.minute);
      } else {
        end = _parseTime(endTimeStr);
      }

      final startDt =
          DateTime(now.year, now.month, now.day, start.hour, start.minute);
      var endDt = DateTime(now.year, now.month, now.day, end.hour, end.minute);

      if (endDt.isBefore(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }

      return !now.isBefore(startDt) && now.isBefore(endDt);
    } catch (e) {
      return false;
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final cleanStr = timeStr.trim().toUpperCase();
      final hasAmPm = cleanStr.endsWith('AM') || cleanStr.endsWith('PM');

      if (hasAmPm) {
        final ampm = cleanStr.substring(cleanStr.length - 2);
        final timePart = cleanStr.substring(0, cleanStr.length - 2).trim();
        final timeParts = timePart.split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);

        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      } else {
        final timeParts = cleanStr.split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final today = DateTime.now().toIso8601String().split('T')[0];

    Stream<QuerySnapshot> activeSessions = FirebaseFirestore.instance
        .collection('active_sessions')
        .where('lecturerId', isEqualTo: uid)
        .snapshots();

    Stream<QuerySnapshot> assignedTasks = FirebaseFirestore.instance
        .collection('exam_assignments')
        .where('lecturerId', isEqualTo: uid)
        .snapshots();

    Stream<QuerySnapshot> todayAttendance = FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: today)
        .snapshots();

    return StreamBuilder<List<dynamic>>(
      stream: CombineLatestStream.list(
          [activeSessions, assignedTasks, todayAttendance]).map((snapshots) {
        final sessionDocs = snapshots[0].docs;
        final assignedDocs = snapshots[1].docs;
        final attendanceDocs = snapshots[2].docs;

        List<Map<String, dynamic>> combined = [];

        for (var doc in sessionDocs) {
          final d = doc.data() as Map<String, dynamic>;
          final startTime = d['startTime'] ?? '--';
          final endTime = d['endTime'] ?? '--';

          final bool isTaken = attendanceDocs.any((att) {
            final attData = att.data() as Map<String, dynamic>;
            return attData['courseCode'] == d['courseCode'] &&
                attData['sessionType'] == d['sessionType'] &&
                attData['room'] == d['room'];
          });

          final live = !isTaken && _isSessionLive(startTime, endTime);

          combined.add({
            'type': d['sessionType'] ?? 'N/A',
            'course': d['courseCode'] ?? 'N/A',
            'date': 'Today',
            'time': startTime,
            'room': d['room'] ?? 'TBA',
            'status': isTaken ? 'TAKEN' : (live ? 'LIVE' : 'SCHEDULED'),
            'isLive': live,
            'isTaken': isTaken,
          });
        }

        for (var doc in assignedDocs) {
          final d = doc.data() as Map<String, dynamic>;
          final startTime = d['startTime'] ?? d['time'] ?? '--';
          final endTime = d['endTime'] ?? '--';

          final bool isTaken = attendanceDocs.any((att) {
            final attData = att.data() as Map<String, dynamic>;
            return attData['courseCode'] == (d['course'] ?? d['courseCode']) &&
                attData['sessionType'] == d['sessionType'] &&
                attData['room'] == d['room'];
          });

          final live = !isTaken && _isSessionLive(startTime, endTime);

          combined.add({
            'type': d['sessionType'] ?? 'N/A',
            'course': d['course'] ?? d['courseCode'] ?? 'N/A',
            'date': 'Today',
            'time': startTime,
            'room': d['room'] ?? 'TBA',
            'status': isTaken ? 'TAKEN' : (live ? 'LIVE' : 'SCHEDULED'),
            'isLive': live,
            'isTaken': isTaken,
          });
        }

        return combined;
      }),
      builder: (context, snapshot) {
        int activeCount = 0;
        List<Map<String, dynamic>> sessions = [];

        if (snapshot.hasData) {
          sessions = List<Map<String, dynamic>>.from(snapshot.data!);
          activeCount = sessions.length;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              const _WelcomeCard(),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _InfoCard(
                        icon: Icons.event,
                        title: 'Today',
                        subtitle: '$activeCount Sessions')),
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
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome Back!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: tealPrimary)),
              Text('Your sessions are shown below.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
      );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoCard(
      {required this.icon, required this.title, required this.subtitle});
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
            Text(title,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: tealDark)),
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
                children: ['COURSE', 'DATE', 'VENUE', 'TIME', 'STATUS']
                    .map((h) => Expanded(
                        child: Center(
                            child: Text(h,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10)))))
                    .toList())),
        ...sessions.asMap().entries.map((e) => Container(
              color: e.key.isEven ? Colors.white : tealLight.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Expanded(
                    child: Center(
                        child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.value['course'],
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(e.value['type'],
                        style:
                            const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ))),
                Expanded(
                    child: Center(
                        child: Text(e.value['date'],
                            style: const TextStyle(fontSize: 10)))),
                Expanded(
                    child: Center(
                        child: Text(e.value['room'],
                            style: const TextStyle(fontSize: 10)))),
                Expanded(
                    child: Center(
                        child: Text(e.value['time'],
                            style: const TextStyle(fontSize: 10)))),
                Expanded(
                    child: Center(
                        child: Text(e.value['status'],
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: e.value['isTaken']
                                    ? Colors.blue
                                    : (e.value['isLive']
                                        ? Colors.green
                                        : Colors.orange))))),
              ]),
            ))
      ]),
    );
  }
}
