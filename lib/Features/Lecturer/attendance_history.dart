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

  bool isSessionCreated = false; // Logic to lock selection and show options
  bool showAssignForm = false;   // To toggle the Assign form view

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

  // This function pushes the created session to the 'courses' metadata
  // so it reflects on the Lecturer Dashboard immediately.
  Future<void> _confirmSessionCreation() async {
    if (selectedCourse == null || selectedType == null) return;

    try {
      // Update the course document to reflect this is the "Active" session for today
      await FirebaseFirestore.instance.collection('courses').doc(selectedCourse).update({
        'type': selectedType,
        'date': 'Today', // Or DateTime.now() formatted
        'status': 'Active',
      });

      setState(() {
        isSessionCreated = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session Created Successfully!"), backgroundColor: tealPrimary),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
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
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: "Create Session"),
            Tab(icon: Icon(Icons.history), text: "View History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCreateSessionTab(), _buildHistoryTab()],
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
          // Disable dropdown if session is already created to prevent accidental changes
          IgnorePointer(
            ignoring: isSessionCreated,
            child: _buildDropdown("Choose Course", selectedCourse, assignedCourses, (v) => setState(() => selectedCourse = v)),
          ),

          const SizedBox(height: 20),
          const Text("Session Type", style: TextStyle(fontWeight: FontWeight.bold, color: tealDark)),
          const SizedBox(height: 10),
          IgnorePointer(
            ignoring: isSessionCreated,
            child: _buildDropdown("Choose Type", selectedType, types, (v) => setState(() => selectedType = v)),
          ),

          const SizedBox(height: 30),

          if (!isSessionCreated)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: tealPrimary, foregroundColor: Colors.white),
                onPressed: (selectedCourse == null || selectedType == null) ? null : _confirmSessionCreation,
                child: const Text("Confirm & Create Session"),
              ),
            ),

          if (isSessionCreated) ...[
            const Divider(height: 40),
            const Text("Session Active", style: TextStyle(color: tealPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _buildActionButton(
              title: "Take Attendance Myself",
              subtitle: "Start scanning students now",
              icon: Icons.qr_code_scanner,
              color: tealPrimary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendancePage(
                courseCode: selectedCourse!,
                sessionType: selectedType!,
              ))),
            ),

            const SizedBox(height: 12),

            _buildActionButton(
              title: showAssignForm ? "Cancel Assignment" : "Assign Invigilator",
              subtitle: showAssignForm ? "Tap to close form" : "Delegate session to another staff",
              icon: showAssignForm ? Icons.close : Icons.person_add,
              color: showAssignForm ? Colors.red : Colors.orange.shade800,
              onTap: () => setState(() => showAssignForm = !showAssignForm),
            ),

            if (showAssignForm) ...[
              const SizedBox(height: 20),
              const Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Invigilator form is now visible below.", style: TextStyle(fontSize: 12, color: tealDark)),
                ),
              ),
              // We reuse the existing Assign logic here or navigate
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Go to Full Assignment Form"),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Assign())),
                ),
              )
            ],

            const SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  isSessionCreated = false;
                  showAssignForm = false;
                }),
                child: const Text("Reset Session Selection", style: TextStyle(color: Colors.grey)),
              ),
            )
          ]
        ],
      ),
    );
  }

  // History and Helper methods remain same as provided in context
  Widget _buildHistoryTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('attendance').where('lecturerId', isEqualTo: uid);
    query = query.orderBy('timestamp', descending: true);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return ListTile(title: Text(d['courseCode']), subtitle: Text(d['date']));
          },
        );
      },
    );
  }

  Widget _buildActionButton({required String title, required String subtitle, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
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