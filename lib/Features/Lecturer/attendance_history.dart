import 'package:flutter/material.dart';
import 'invigilator_dashboard.dart';
import 'select_course.dart';
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
  final int _currentIndex = 2; // Attendance History tab active
  String? selectedCourse;
  String? selectedType;

  final List<String> courses = ["COM411", "COM412", "COM413"];
  final List<String> types = ["Class", "Lab", "Exam"];

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

  // Dummy data to show table representation
  final List<Map<String, String>> attendanceData = List.generate(
    20,
    (index) => {
      "date": "${index + 1} March",
      "course": "COM411",
      "type": index % 2 == 0 ? "Class" : "Lab",
      "year": "4",
      "present": "${70 + index}",
      "absent": "$index",
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'AAS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
                backgroundColor: Colors.teal,
                radius: 15,
                child:
                    Icon(Icons.person_outline, color: Colors.white, size: 18)),
          ),
        ],
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBox("Total Sessions 128"),
                  _buildStatBox("Class Sessions 79"),
                  _buildStatBox("Lab Sessions 30"),
                  _buildStatBox("Exam Sessions 40"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildCourseDropdown(),
                  const SizedBox(width: 10),
                  _buildTypeDropdown(),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Divider(
                color: tealPrimary, thickness: 2, indent: 10, endIndent: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TableHeaderText("DATE"),
                  _TableHeaderText("COURSE"),
                  _TableHeaderText("TYPE"),
                  _TableHeaderText("YEAR"),
                  _TableHeaderText("PRESENT"),
                  _TableHeaderText("ABSENT"),
                  _TableHeaderText("ACTION"),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendanceData.length,
              itemBuilder: (context, index) {
                final item = attendanceData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TableCellText(item['date']!),
                      _TableCellText(item['course']!),
                      _TableCellText(item['type']!),
                      _TableCellText(item['year']!),
                      _TableCellText(item['present']!),
                      _TableCellText(item['absent']!),
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ViewList()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
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
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      //NAVIGATION ONLY
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
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

  Widget _buildStatBox(String text) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFD9F2FF),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, color: Colors.black87),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.8),
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCourse,
          hint: const Text("Select Course", style: TextStyle(fontSize: 9)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
          style: const TextStyle(fontSize: 9, color: Colors.black),
          onChanged: (String? newValue) {
            setState(() {
              selectedCourse = newValue;
            });
          },
          items: courses.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.8),
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          hint: const Text("Select Type", style: TextStyle(fontSize: 9)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
          style: const TextStyle(fontSize: 9, color: Colors.black),
          onChanged: (String? newValue) {
            setState(() {
              selectedType = newValue;
            });
          },
          items: types.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: tealPrimary,
        border: Border.all(color: Colors.black),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String text;
  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String text;
  const _TableCellText(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}
