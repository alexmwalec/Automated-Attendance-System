import 'package:flutter/material.dart';
import 'select_course.dart'; // Import the Course page

// ─── Constants ───────────────────────────────────────────────────────────────
const Color tealPrimary = Color(0xFF2E9E8E); // main teal from screenshot
const Color tealDark = Color(0xFF227A6D); // darker shade for headers
const Color tealLight = Color(0xFFE0F2F0); // light teal background tint
const Color tealAccent = Color(0xFF26A69A); // accent / active items

// ─── Entry Widget ─────────────────────────────────────────────────────────────
class InvigilatorDashboard extends StatefulWidget {
  const InvigilatorDashboard({super.key});

  @override
  State<InvigilatorDashboard> createState() => _InvigilatorDashboardState();
}

class _InvigilatorDashboardState extends State<InvigilatorDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _DashboardPage(),
    const Course(), // This now opens your select-course.dart page
    const _AttendanceHistoryPage(),
    const _AssignTaskPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,

      // ── AppBar — matches screenshot header style ─────────────────────────
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // AAS on the left
                const Text(
                  'AAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Notification icon
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {},
                ),
                // Profile icon
                IconButton(
                  icon: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),

      // ── Body ────────────────────────────────────────────────────────────────
      body: _pages[_currentIndex],

      // ── Bottom Navigation — teal style ──────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
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

// ─── Dashboard Page ───────────────────────────────────────────────────────────
class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Card — matches screenshot card style ────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              border: Border.all(color: tealPrimary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: tealPrimary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tealPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Use this dashboard to manage class, lab, and exam attendance, assign invigilators, and monitor attendance reports',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Info Cards Row ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.monitor,
                  iconColor: tealPrimary,
                  title: 'Courses Assigned',
                  subtitle: '3 Courses',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.calendar_today,
                  iconColor: tealDark,
                  title: 'Session Today',
                  subtitle: '1 Class/ 2 Lab/ 1 Exam',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Today's Sessions ───────────────────────────────────────────
          const _SectionHeader(title: "TODAY'S SESSIONS"),
          const SizedBox(height: 8),
          const _TodaysSessionsTable(),
          const SizedBox(height: 20),

          // ── Approved Absence ───────────────────────────────────────────
          const _SectionHeader(title: 'APPROVED ABSENCE'),
          const SizedBox(height: 8),
          const _ApprovedAbsenceTable(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Placeholder Pages ────────────────────────────────────────────────────────
class _TakeAttendancePage extends StatelessWidget {
  const _TakeAttendancePage();
  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
    icon: Icons.check_circle_outline,
    title: 'Take Attendance',
    subtitle: 'Record student attendance',
  );
}

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
  Widget build(BuildContext context) => const _PlaceholderPage(
    icon: Icons.assignment_outlined,
    title: 'Assign Task',
    subtitle: 'Assign tasks to students',
  );
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

// ─── Info Card ────────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: tealPrimary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: tealPrimary.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
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
        fontSize: 13,
        letterSpacing: 0.6,
      ),
    );
  }
}

// ─── Today's Sessions Table ───────────────────────────────────────────────────
class _TodaysSessionsTable extends StatelessWidget {
  const _TodaysSessionsTable();

  @override
  Widget build(BuildContext context) {
    const headers = ['TYPE', 'COURSE', 'DATE', 'TIME', 'ROOM'];
    const rows = [
      ['Class', 'Com4', '14 May', '08:30', 'Ck 2'],
      ['Lab', 'Com3', '14 May', '08:30', 'Ck 2'],
      ['Exam', 'Com5', '14 May', '08:30', 'Ck 2'],
    ];

    final typeColors = {
      'Class': tealPrimary,
      'Lab': Colors.green.shade600,
      'Exam': Colors.orange.shade700,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tealPrimary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Header row
            Container(
              color: tealPrimary,
              child: Row(
                children: headers
                    .map(
                      (h) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 4,
                          ),
                          child: Text(
                            h,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Data rows
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              final typeColor = typeColors[row[0]] ?? Colors.grey;
              return Container(
                color: i.isEven ? Colors.white : tealLight.withOpacity(0.5),
                child: Row(
                  children: row.asMap().entries.map((cell) {
                    final isType = cell.key == 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 4,
                        ),
                        child: isType
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.13),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cell.value,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
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
      ),
    );
  }
}

// ─── Approved Absence Table ───────────────────────────────────────────────────
class _ApprovedAbsenceTable extends StatelessWidget {
  const _ApprovedAbsenceTable();

  @override
  Widget build(BuildContext context) {
    const headers = ['NAME', 'REG NO', 'COURSE', 'YR', 'REASON'];
    const rows = [
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '4', '-'],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', '-'],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', '-'],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', '-'],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', '-'],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', '-'],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '2', '-'],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '2', '-'],
    ];

    // Column flex widths so REG NO doesn't squash others
    const flexes = [2, 3, 2, 1, 2];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tealPrimary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Header row
            Container(
              color: tealPrimary,
              child: Row(
                children: headers
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        flex: flexes[e.key],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 4,
                          ),
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Data rows
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Container(
                color: i.isEven ? Colors.white : tealLight.withOpacity(0.5),
                child: Row(
                  children: row
                      .asMap()
                      .entries
                      .map(
                        (cell) => Expanded(
                          flex: flexes[cell.key],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            child: Text(
                              cell.value,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
