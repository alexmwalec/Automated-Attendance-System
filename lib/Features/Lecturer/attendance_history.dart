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

  @override
  void initState() {
    super.initState();
    _fetchAssignedCourses();
  }

  Future<void> _fetchAssignedCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    var doc = await FirebaseFirestore.instance.collection('lecturers').doc(uid).get();
    if (doc.exists) {
      List<dynamic> rawList = doc.data()?['assignedCourses'] ?? [];
      List<String> codes = [];
      for (var item in rawList) {
        String val = item.toString();
        val.contains(',') ? codes.addAll(val.split(',').map((e) => e.trim())) : codes.add(val.trim());
      }
      setState(() => assignedCourses = codes);
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    if (index == 0 || index == 1) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LecturerDashboard(initialIndex: index)), (route) => false);
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Assign()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('attendance').where('lecturerId', isEqualTo: uid);
    if (selectedCourse != null) query = query.where('courseCode', isEqualTo: selectedCourse);
    if (selectedType != null) query = query.where('sessionType', isEqualTo: selectedType);
    query = query.orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(backgroundColor: tealPrimary, automaticallyImplyLeading: false, title: const Text('AAS History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Expanded(child: _buildDropdown("Course", selectedCourse, assignedCourses, (v) => setState(() => selectedCourse = v))),
          const SizedBox(width: 8),
          Expanded(child: _buildDropdown("Type", selectedType, types, (v) => setState(() => selectedType = v))),
          IconButton(icon: const Icon(Icons.filter_alt_off), onPressed: () => setState(() { selectedCourse = null; selectedType = null; }))
        ])),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const Center(child: Text("No records found."));
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final d = docs[i].data();
                return Card(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: ListTile(
                  title: Text("${d['courseCode']} - ${d['sessionType']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Date: ${d['date']} | Present: ${d['totalPresent']}"),
                  trailing: IconButton(icon: const Icon(Icons.visibility, color: tealPrimary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewList(attendanceData: d)))),
                ));
              },
            );
          },
        ))
      ]),
      bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, onTap: _onNavTap, type: BottomNavigationBarType.fixed, backgroundColor: tealPrimary, selectedItemColor: Colors.white, unselectedItemColor: Colors.white70, items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Attendance'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Assign'),
      ]),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), border: Border.all(color: tealPrimary.withOpacity(0.3))),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, hint: Text(hint, style: const TextStyle(fontSize: 12)), value: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: onChanged)),
  );
}