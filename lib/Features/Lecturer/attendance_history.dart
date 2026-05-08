import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lecturer_dashboard.dart';
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

  final List<String> courses = ["COM 421", "COM 424", "INF 423", "COM 423"];
  final List<String> types = ["Class", "Lab", "Exam"];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LecturerDashboard(initialIndex: 0)),
            (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LecturerDashboard(initialIndex: 1)),
            (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Assign()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('attendance');

    //  Apply Dynamic Filtering based on state
    if (selectedCourse != null) {
      query = query.where('courseCode', isEqualTo: selectedCourse);
    }
    if (selectedType != null) {
      query = query.where('sessionType', isEqualTo: selectedType);
    }

    query = query.orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('AAS History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Course", selectedCourse, courses, (v) => setState(() => selectedCourse = v))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDropdown("Type", selectedType, types, (v) => setState(() => selectedType = v))),
                    // Reset Button
                    IconButton(
                      icon: Icon(
                          Icons.filter_alt_off,
                          color: (selectedCourse == null && selectedType == null) ? Colors.grey : tealPrimary
                      ),
                      onPressed: () => setState(() {
                        selectedCourse = null;
                        selectedType = null;
                      }),
                    )
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: tealPrimary, thickness: 2),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("Query Error: ${snapshot.error}"),
                  ));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: tealPrimary));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text("No records found for the selected filters",
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 45,
                      columnSpacing: 25,
                      columns: const [
                        DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Course", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Present", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data();
                        return DataRow(cells: [
                          DataCell(Text(data['date'] ?? '')),
                          DataCell(Text(data['courseCode'] ?? '')),
                          DataCell(Text(data['sessionType'] ?? '')),
                          DataCell(Center(child: Text("${data['totalPresent'] ?? 0}"))),
                          DataCell(
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: tealPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: const Size(50, 30)
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ViewList(attendanceData: data)),
                                );
                              },
                              child: const Text("VIEW", style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
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
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Assign Task'),
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: tealPrimary.withOpacity(0.3))
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}