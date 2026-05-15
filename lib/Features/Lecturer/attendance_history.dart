import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
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

  List<String> assignedCourses = [];
  final List<String> types = ["Class", "Lab", "Exam"];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedCourses();
  }

  Future<void> _fetchAssignedCourses() async {
    try {
      // Use actual Auth UID
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      var doc = await FirebaseFirestore.instance.collection('lecturers').doc(uid).get();
      if (doc.exists) {
        List<dynamic> rawList = doc.data()?['assignedCourses'] ?? [];
        List<String> codes = [];

        // Handle the format: ["COM 423 , INF423"] by splitting string items
        for (var item in rawList) {
          String val = item.toString();
          if (val.contains(',')) {
            codes.addAll(val.split(',').map((e) => e.trim()));
          } else {
            codes.add(val.trim());
          }
        }

        setState(() {
          assignedCourses = codes;
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching courses for filter: $e");
      setState(() => _isLoadingCourses = false);
    }
  }

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
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Query filtered by this specific lecturer
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('attendance')
        .where('lecturerId', isEqualTo: uid);

    if (selectedCourse != null) {
      query = query.where('courseCode', isEqualTo: selectedCourse);
    }

    if (selectedType != null) {
      query = query.where('sessionType', isEqualTo: selectedType);
    }

    // Note: Requires composite index created via the link in the error console
    query = query.orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('AAS History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter Records',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tealPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildDropdown("Course", selectedCourse, assignedCourses,
                                (v) => setState(() => selectedCourse = v))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildDropdown("Type", selectedType, types,
                                (v) => setState(() => selectedType = v))),
                    IconButton(
                      icon: Icon(Icons.filter_alt_off,
                          color: (selectedCourse == null && selectedType == null)
                              ? Colors.grey
                              : tealPrimary),
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

          // Records Section
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("Ensure Index is Created: ${snapshot.error}",
                          textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    ),
                  );
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
                        Text("No records found for your assigned courses",
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: tealPrimary.withOpacity(0.1))),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text("${data['courseCode']} - ${data['sessionType']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: tealDark)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                              "Date: ${data['date']} | Present: ${data['totalPresent']}/${data['totalExpected'] ?? '?'}",
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: tealPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.visibility, color: tealPrimary),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ViewList(attendanceData: data))),
                          ),
                        ),
                      ),
                    );
                  },
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

  Widget _buildDropdown(
      String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: tealPrimary.withOpacity(0.3))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          value: value,
          items: items
              .map((e) => DropdownMenuItem(
              value: e, child: Text(e, style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}