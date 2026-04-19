import 'package:flutter/material.dart';
import 'select_course.dart';
import 'assign.dart';
import 'attendance_history.dart';
import 'profile.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);
const Color tealAccent = Color(0xFF26A69A);

// Entry Widget
class InvigilatorDashboard extends StatefulWidget {
  final int initialIndex;

  const InvigilatorDashboard({super.key, this.initialIndex = 0});

  @override
  State<InvigilatorDashboard> createState() => _InvigilatorDashboardState();
}

class _InvigilatorDashboardState extends State<InvigilatorDashboard> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const _DashboardPage(),
    const Course(),
    const _AttendanceHistoryPage(),
    const _AssignTaskPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 60,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'AAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                // Profile icon — tapping navigates to Profile page
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Profile()),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tealDark,
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────────
      body: _pages[_currentIndex],

      // ── Bottom Navigation ────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Assign()),
            );
          } else if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceHistory()),
            );
          } else {
            setState(() => _currentIndex = i);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Attendance History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Assign Task',
          ),
        ],
      ),
    );
  }
}

// Dashboard Page
class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.monitor_outlined,
                  iconColor: tealPrimary,
                  title: 'Courses Assigned',
                  subtitle: '3 Courses',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: tealDark,
                  title: 'Session Today',
                  subtitle: '1 Class/ 2 Lab/ 1 Exam',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: "TODAY'S SESSION'S"),
          const SizedBox(height: 8),
          const _TodaysSessionsTable(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Welcome Card ─────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tealPrimary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: tealPrimary.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: tealPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Welcome to the Automated Attendance System.\n'
            'Use this dashboard to manage class, lab, and exam attendance,\n'
            'assign invigilators, and monitor attendance reports',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Info Card
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tealPrimary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: tealPrimary.withOpacity(0.07),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: tealDark,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }
}

// Today's Sessions Table
class _TodaysSessionsTable extends StatelessWidget {
  const _TodaysSessionsTable();

  @override
  Widget build(BuildContext context) {
    const headers = ['TYPE', 'COURSE', 'DATE', 'TIME', 'ROOM'];
    const rows = [
      ['Class', 'Com4', '14 may', '08:30', 'Ck 2'],
      ['Lab', 'Com3', '14 may', '08:30', 'Ck 2'],
      ['Exam', 'Com5', '14 may', '08:30', 'Ck 2'],
    ];

    final typeColors = {
      'Class': tealPrimary,
      'Lab': const Color(0xFF43A047),
      'Exam': const Color(0xFFEF6C00),
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tealPrimary.withOpacity(0.3)),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: tealPrimary,
            child: Row(
              children: headers.map((h) {
                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      h,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final typeColor = typeColors[row[0]] ?? Colors.grey;
            return Container(
              color: i.isEven ? Colors.white : const Color(0xFFF0FAF9),
              child: Row(
                children: row.asMap().entries.map((cell) {
                  final isType = cell.key == 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: isType
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cell.value,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            )
                          : Text(
                              cell.value,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                            ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Placeholder Pages ────────────────────────────────────────────────────────
class _AttendanceHistoryPage extends StatelessWidget {
  const _AttendanceHistoryPage();
  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
        icon: Icons.history_outlined,
        title: 'Attendance History',
        subtitle: 'View past attendance records',
      );
}

class _AssignTaskPage extends StatelessWidget {
  const _AssignTaskPage();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Assign()),
      );
    });
    return const Center(
      child: CircularProgressIndicator(color: tealPrimary),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: tealPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tealPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
