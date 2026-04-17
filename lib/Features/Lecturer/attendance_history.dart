import 'package:flutter/material.dart';
import 'invigilator_dashboard.dart';
import 'assign.dart';
import 'viewlist.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  final int _currentIndex = 2;

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const InvigilatorDashboard(initialIndex: 0),
        ),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const InvigilatorDashboard(initialIndex: 1),
        ),
        (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Assign()),
      );
    }
  }

  final List<Map<String, String>> attendanceData = [
    {
      "date": "02 March",
      "course": "COM411",
      "type": "Class",
      "year": "4",
      "present": "70",
      "absent": "0",
    },
    {
      "date": "12 March",
      "course": "COM411",
      "type": "lab",
      "year": "4",
      "present": "24",
      "absent": "0",
    },
    {
      "date": "1 April",
      "course": "COM411",
      "type": "Exam",
      "year": "4",
      "present": "89",
      "absent": "7",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,

      // ── AppBar — consistent with rest of the app ──────────────────────────
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
                Container(
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
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tealPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // ── Stat boxes ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatBox("Total Sessions 128"),
                  _buildStatBox("Class Sessions 79"),
                  _buildStatBox("Lab Sessions 30"),
                  _buildStatBox("Exam Sessions 40"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Filter dropdowns ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  _buildDropdown("Select Course"),
                  const SizedBox(width: 10),
                  _buildDropdown("Select Type"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(
              color: tealPrimary,
              thickness: 2,
              indent: 10,
              endIndent: 10,
            ),

            // ── Table ─────────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 28,
                ),
                child: DataTable(
                  columnSpacing: 12,
                  horizontalMargin: 10,
                  headingRowHeight: 40,
                  dataRowMinHeight: 45,
                  dataRowMaxHeight: 50,
                  columns: const [
                    DataColumn(label: _TableHeaderText("DATE")),
                    DataColumn(label: _TableHeaderText("COURSE")),
                    DataColumn(label: _TableHeaderText("TYPE")),
                    DataColumn(label: _TableHeaderText("YEAR")),
                    DataColumn(label: _TableHeaderText("PRESENT")),
                    DataColumn(label: _TableHeaderText("ABSENT")),
                    DataColumn(label: _TableHeaderText("ACTION")),
                  ],
                  rows: attendanceData.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(_TableCellText(item['date']!)),
                        DataCell(_TableCellText(item['course']!)),
                        DataCell(_TableCellText(item['type']!)),
                        DataCell(_TableCellText(item['year']!)),
                        DataCell(_TableCellText(item['present']!)),
                        DataCell(_TableCellText(item['absent']!)),
                        DataCell(
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ViewList(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tealPrimary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "VIEW",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
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

  Widget _buildStatBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD9F2FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black45, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontSize: 10)),
          const Icon(Icons.keyboard_arrow_down, size: 14),
        ],
      ),
    );
  }
}

// ─── Table Header Text ────────────────────────────────────────────────────────
class _TableHeaderText extends StatelessWidget {
  final String text;
  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 10,
        color: Colors.black,
      ),
    );
  }
}

// ─── Table Cell Text ──────────────────────────────────────────────────────────
class _TableCellText extends StatelessWidget {
  final String text;
  const _TableCellText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, color: Colors.black87),
    );
  }
}
