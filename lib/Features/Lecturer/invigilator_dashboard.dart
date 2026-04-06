import 'package:flutter/material.dart';

class InvigilatorDashboard extends StatelessWidget {
  const InvigilatorDashboard({super.key});

  static const Color unimaPurple = Color(0xFF5D00D2);
  static const Color unimaGold = Color(0xFFC5A021);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with hamburger menu
      appBar: AppBar(
        backgroundColor: unimaPurple,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Open menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      //Drawer (slides in from left)
      drawer: const AppDrawer(),

      // Main Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Welcome to the Automated Attendance System. '
                    'Use this dashboard to manage class, lab, and exam '
                    'attendance, assign invigilators, and monitor '
                    'attendance reports',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),

            // Info Cards Row
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.monitor,
                    iconColor: Colors.blue.shade600,
                    title: 'Courses Assigned',
                    subtitle: '3 Courses',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.calendar_today,
                    iconColor: Colors.purple.shade600,
                    title: 'Session Today',
                    subtitle: '1 Class/ 2 Lab/ 1 Exam',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Today's Sessions Table
            const _SectionHeader(title: "TODAY'S SESSION'S"),
            const SizedBox(height: 8),
            const _TodaysSessionsTable(),
            const SizedBox(height: 20),

            // Approved Absence Table
            const _SectionHeader(title: 'APPROVED ABSENCE'),
            const SizedBox(height: 8),
            const _ApprovedAbsenceTable(),
          ],
        ),
      ),
    );
  }
}

//Drawer

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const Color unimaPurple = Color(0xFF5D00D2);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header with close (X) button
          Container(
            color: unimaPurple,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 8,
              bottom: 16,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 34, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Invigilator',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close menu',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Nav label
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MAIN NAVIGATION MENU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.black45,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Nav items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: const [
                _DrawerItem(icon: Icons.dashboard, title: 'Dashboard', route: '/dashboard', isActive: true),
                _DrawerItem(icon: Icons.qr_code_scanner, title: 'Take Attendance', route: '/scanner'),
                _DrawerItem(icon: Icons.person_outline, title: 'Profile', route: '/profile'),
                _DrawerItem(icon: Icons.assignment_outlined, title: 'Select Course', route: '/course'),
                _DrawerItem(icon: Icons.edit_note, title: 'Write Report', route: '/report'),
                _DrawerItem(icon: Icons.history, title: 'Attendance History', route: '/attendance_history'),
                _DrawerItem(icon: Icons.bar_chart, title: 'Analytics', route: '/analytics'),
                _DrawerItem(icon: Icons.admin_panel_settings, title: 'Assign Invigilator', route: '/assign'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    this.isActive = false,
  });

  static const Color unimaPurple = Color(0xFF5D00D2);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isActive ? unimaPurple : Colors.transparent,
            width: 4,
          ),
        ),
        color: isActive ? unimaPurple.withOpacity(0.06) : Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        leading: isActive
            ? Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: unimaPurple, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        )
            : Icon(icon, color: Colors.black54, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? unimaPurple : Colors.black87,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // close drawer first
          Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}

// ─── Info Card ───────────────────────────────────────────────────────────────

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
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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

  static const Color unimaPurple = Color(0xFF5D00D2);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: unimaPurple,
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    );
  }
}

// Today's Sessions Table

class _TodaysSessionsTable extends StatelessWidget {
  const _TodaysSessionsTable();

  static const Color unimaPurple = Color(0xFF5D00D2);

  @override
  Widget build(BuildContext context) {
    const headers = ['TYPE', 'COURSE', 'DATE', 'TIME', 'ROOM'];
    const rows = [
      ['Class', 'Com4', '14 may', '08:30', 'Ck 2'],
      ['Lab', 'Com3', '14 may', '08:30', 'Ck 2'],
      ['Exam', 'Com5', '14 may', '08:30', 'Ck 2'],
    ];

    final typeColors = {
      'Class': Colors.blue,
      'Lab': Colors.green,
      'Exam': Colors.orange,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            color: unimaPurple,
            child: Row(
              children: headers
                  .map(
                    (h) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: Text(
                      h,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
              color: i.isEven ? Colors.white : const Color(0xFFF5F5F5),
              child: Row(
                children: row.asMap().entries.map((cell) {
                  final isType = cell.key == 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      child: isType
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          cell.value,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                          : Text(cell.value, style: const TextStyle(fontSize: 12)),
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

// Approved Absence Table

class _ApprovedAbsenceTable extends StatelessWidget {
  const _ApprovedAbsenceTable();

  static const Color unimaPurple = Color(0xFF5D00D2);

  @override
  Widget build(BuildContext context) {
    const headers = ['NAME', 'REG NO', 'COURSE', 'YEAR', 'REASON'];
    const rows = [
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '4', ''],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', ''],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', ''],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', ''],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', ''],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', ''],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '3', ''],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '2', ''],
      ['Sulphuric', 'bed-com-27-22', 'com4ll', '2', ''],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            color: unimaPurple,
            child: Row(
              children: headers
                  .map(
                    (h) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: Text(
                      h,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
              color: i.isEven ? Colors.white : const Color(0xFFF5F5F5),
              child: Row(
                children: row
                    .map(
                      (cell) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                      child: Text(cell, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    ),
                  ),
                )
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}