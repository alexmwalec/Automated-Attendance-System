import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lecturer_dashboard.dart';
import 'assign.dart';
import 'viewlist.dart';
import 'take_attendance.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});
  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _currentIndex = 2;

  // Selection state for "Create Session"
  String? selectedCourse;
  String? selectedType;
  List<String> assignedCourses = [];
  final List<String> types = ["Class", "Lab", "Exam"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        title: const Text('Session Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: "Create Session"),
            Tab(icon: Icon(Icons.history), text: "View History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateSessionTab(),
          _buildHistoryTab(),
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
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Manager'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Assign'),
        ],
      ),
    );
  }

  Widget _buildCreateSessionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold, color: tealDark)),
          const SizedBox(height: 10),
          _buildDropdown("Choose Course", selectedCourse, assignedCourses, (v) => setState(() => selectedCourse = v)),

          const SizedBox(height: 25),
          const Text("Session Type", style: TextStyle(fontWeight: FontWeight.bold, color: tealDark)),
          const SizedBox(height: 10),
          _buildDropdown("Choose Type", selectedType, types, (v) => setState(() => selectedType = v)),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          const Text("How would you like to record attendance?",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 20),

          // Option 1: Take Attendance Now
          _buildActionButton(
            title: "Take Attendance Myself",
            subtitle: "Open the QR scanner now",
            icon: Icons.qr_code_scanner,
            color: tealPrimary,
            onTap: (selectedCourse == null || selectedType == null) ? null : () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AttendancePage(
                courseCode: selectedCourse!,
                sessionType: selectedType!,
              )));
            },
          ),

          const SizedBox(height: 16),

          // Option 2: Assign to Invigilator
          _buildActionButton(
            title: "Assign Invigilator",
            subtitle: "Delegate this session to someone else",
            icon: Icons.person_add_alt_1,
            color: Colors.orange.shade700,
            onTap: (selectedCourse == null || selectedType == null) ? null : () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const Assign()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('attendance').where('lecturerId', isEqualTo: uid);
    query = query.orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("No records found."));

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(10),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text("${d['courseCode']} - ${d['sessionType']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Date: ${d['date']} | Present: ${d['totalPresent']}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: tealPrimary),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewList(attendanceData: d))),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({required String title, required String subtitle, required IconData icon, required Color color, VoidCallback? onTap}) {
    bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDisabled ? Colors.grey.shade300 : color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: tealPrimary.withOpacity(0.3))),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        hint: Text(hint),
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}