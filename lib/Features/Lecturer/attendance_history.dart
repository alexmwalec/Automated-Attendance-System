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
  String? selectedCourse;
  String? selectedType;
  String? selectedYear;

  final List<String> courses = ["COM411", "COM412", "COM413"];
  final List<String> types = ["Class", "Lab", "Exam"];
  final List<String> years = ["1", "2", "3", "4"];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const InvigilatorDashboard(initialIndex: 0)),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const InvigilatorDashboard(initialIndex: 1)),
        (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Assign()),
      );
    }
  }

  final List<Map<String, dynamic>> attendanceData = [
    {
      "date": "14 may",
      "course": "com411",
      "type": "Class",
      "year": "4",
      "present": "70",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Class",
      "year": "4",
      "present": "34",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Class",
      "year": "3",
      "present": "89",
      "absent": "7"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Class",
      "year": "4",
      "present": "76",
      "absent": "1"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Class",
      "year": "4",
      "present": "98",
      "absent": "7"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "5",
      "present": "64",
      "absent": "4"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "3",
      "present": "70",
      "absent": "2"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "3",
      "present": "24",
      "absent": "1"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "3",
      "present": "75",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "3",
      "present": "54",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "3",
      "present": "76",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "1",
      "present": "38",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "1",
      "present": "76",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Lab",
      "year": "2",
      "present": "70",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Exam",
      "year": "2",
      "present": "76",
      "absent": "8"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Exam",
      "year": "3",
      "present": "70",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Exam",
      "year": "3",
      "present": "70",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Exam",
      "year": "3",
      "present": "97",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Exam",
      "year": "2",
      "present": "45",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Exam",
      "year": "1",
      "present": "100",
      "absent": "0"
    },
    {
      "date": "14 may",
      "course": "com411",
      "type": "Exam",
      "year": "1",
      "present": "60",
      "absent": "0"
    },
  ];

  List<Map<String, dynamic>> get filteredData {
    return attendanceData.where((item) {
      final courseMatch = selectedCourse == null ||
          item['course'].toString().toUpperCase() == selectedCourse;
      final typeMatch = selectedType == null || item['type'] == selectedType;
      final yearMatch = selectedYear == null || item['year'] == selectedYear;
      return courseMatch && typeMatch && yearMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = filteredData;

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'AAS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: CircleAvatar(
              backgroundColor: tealDark,
              radius: 15,
              child: Icon(Icons.person_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              // vertical scroll
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page title
                  const Text(
                    'Attendance History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: tealPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stat boxes row
                  Row(
                    children: [
                      _buildStatBox("Total Sessions\n128"),
                      const SizedBox(width: 5),
                      _buildStatBox("Class Sessions\n79"),
                      const SizedBox(width: 5),
                      _buildStatBox("Lab Sessions\n80"),
                      const SizedBox(width: 5),
                      _buildStatBox("Exam Sessions\n40"),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Filter dropdowns
                  Row(
                    children: [
                      _buildDropdown<String>(
                        hint: "Select Course",
                        value: selectedCourse,
                        items: courses,
                        onChanged: (v) => setState(() => selectedCourse = v),
                      ),
                      const SizedBox(width: 8),
                      _buildDropdown<String>(
                        hint: "Select Type",
                        value: selectedType,
                        items: types,
                        onChanged: (v) => setState(() => selectedType = v),
                      ),
                      const SizedBox(width: 8),
                      _buildDropdown<String>(
                        hint: "Select Year",
                        value: selectedYear,
                        items: years,
                        onChanged: (v) => setState(() => selectedYear = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Divider
                  const Divider(color: tealPrimary, thickness: 2),
                  const SizedBox(height: 4),

                  // Horizontally scrollable table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 32,
                      dataRowMinHeight: 28,
                      dataRowMaxHeight: 32,
                      columnSpacing: 16,
                      horizontalMargin: 8,
                      dividerThickness: 0,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                      dataTextStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      columns: const [
                        DataColumn(label: Text("DATE")),
                        DataColumn(label: Text("COURSE")),
                        DataColumn(label: Text("TYPE")),
                        DataColumn(label: Text("YEAR")),
                        DataColumn(label: Text("PRESENT")),
                        DataColumn(label: Text("ABSENT")),
                        DataColumn(label: Text("ACTION")),
                      ],
                      rows: List.generate(data.length, (index) {
                        final item = data[index];
                        final isEven = index % 2 == 0;
                        return DataRow(
                          color: WidgetStateProperty.all(
                            isEven
                                ? Colors.transparent
                                : tealPrimary.withOpacity(0.06),
                          ),
                          cells: [
                            DataCell(Text(item['date']!)),
                            DataCell(Text(item['course']!)),
                            DataCell(Text(item['type']!)),
                            DataCell(Text(item['year']!)),
                            DataCell(Text(item['present']!)),
                            DataCell(Text(item['absent']!)),
                            DataCell(
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ViewList()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tealPrimary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    "VIEW",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Generate report & Download buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: tealPrimary, width: 1.5),
                            foregroundColor: tealPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            "Generate report",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tealPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            "Download",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 9),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD9F2FF),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1a4a6e),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black87, width: 0.8),
          borderRadius: BorderRadius.circular(3),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            hint: Text(
              hint,
              style: const TextStyle(fontSize: 9, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 14, color: Colors.black54),
            style: const TextStyle(fontSize: 9, color: Colors.black87),
            isDense: true,
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<T>>((T val) {
              return DropdownMenuItem<T>(
                value: val,
                child: Text(val.toString()),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
