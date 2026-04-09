import 'package:flutter/material.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  // Mock data representing the table
  final List<Map<String, String>> attendanceData = [
    {"date": "14 may", "course": "com411", "type": "Class", "year": "4", "present": "70", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Class", "year": "4", "present": "24", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Class", "year": "4", "present": "89", "absent": "7"},
    {"date": "14 may", "course": "com411", "type": "Class", "year": "4", "present": "99", "absent": "1"},
    {"date": "14 may", "course": "com411", "type": "Class", "year": "4", "present": "98", "absent": "7"},
    {"date": "14 may", "course": "com411", "type": "Lab", "year": "4", "present": "64", "absent": "7"},
    {"date": "14 may", "course": "com411", "type": "Lab", "year": "3", "present": "70", "absent": "4"},
    {"date": "14 may", "course": "com411", "type": "Lab", "year": "3", "present": "24", "absent": "2"},
    {"date": "14 may", "course": "com411", "type": "Lab", "year": "3", "present": "25", "absent": "1"},
    {"date": "14 may", "course": "com411", "type": "Lab", "year": "3", "present": "58", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Lab", "year": "3", "present": "70", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Lab", "year": "2", "present": "21", "absent": "7"},
    {"date": "14 may", "course": "com411", "type": "Lab", "year": "2", "present": "70", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Exam", "year": "2", "present": "70", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Exam", "year": "2", "present": "70", "absent": "5"},
    {"date": "14 may", "course": "com411", "type": "Exam", "year": "2", "present": "70", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Exam", "year": "2", "present": "67", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Exam", "year": "2", "present": "45", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Exam", "year": "1", "present": "100", "absent": "0"},
    {"date": "14 may", "course": "com411", "type": "Exam", "year": "1", "present": "60", "absent": "4"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: tealPrimary,
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
              backgroundColor: Colors.grey,
              radius: 15,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Placeholder for the top empty section
            Container(
              height: 80,
              color: tealLight.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            // Stats Row
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
            // Filters Row - "Select Year" removed here
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildDropdown("Select Course"),
                  const SizedBox(width: 10),
                  _buildDropdown("Select Type"),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Divider line
            const Divider(color: tealPrimary, thickness: 2, indent: 10, endIndent: 10),
            // Table Headers
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
            // Table Content
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendanceData.length,
              itemBuilder: (context, index) {
                final item = attendanceData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tealPrimary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              "View",
                              style: TextStyle(color: Colors.white, fontSize: 10),
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
            // Bottom Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton("Generate report"),
                  const SizedBox(width: 20),
                  _buildActionButton("Downloaded"),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: tealPrimary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
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

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.8),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 9)),
          const Icon(Icons.keyboard_arrow_down, size: 14),
        ],
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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
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