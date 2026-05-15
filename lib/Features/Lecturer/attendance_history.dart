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

  String? selectedCourse;
  String? selectedType;
  List<String> assignedCourses = [];
  final List<String> types = ["Class", "Lab", "Exam"];

  bool isLoading = true;

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
      setState(() {
        assignedCourses = codes;
        isLoading = false;
      });
    }
  }

  Future<void> _createSession() async {
    if (selectedCourse == null || selectedType == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    setState(() => isLoading = true);
    try {
      String sessionId = "${uid}_$selectedCourse";

      await FirebaseFirestore.instance.collection('active_sessions').doc(sessionId).set({
        'lecturerId': uid,
        'courseCode': selectedCourse,
        'sessionType': selectedType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        selectedCourse = null;
        selectedType = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session Created! Check the list below."), backgroundColor: tealPrimary),
      );
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error creating session: $e");
    }
  }

  Future<void> _endSession(String sessionId) async {
    await FirebaseFirestore.instance.collection('active_sessions').doc(sessionId).delete();
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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(icon: Icon(Icons.add_task), text: "Manage"),
            Tab(icon: Icon(Icons.history), text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildManageSessionsTab(), _buildHistoryTab()],
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

  Widget _buildManageSessionsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Create New Session", style: TextStyle(fontWeight: FontWeight.bold, color: tealPrimary, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildDropdown("Select Course", selectedCourse, assignedCourses, (v) => setState(() => selectedCourse = v)),
                  const SizedBox(height: 10),
                  _buildDropdown("Session Type", selectedType, types, (v) => setState(() => selectedType = v)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: tealPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                      onPressed: (selectedCourse == null || selectedType == null) ? null : _createSession,
                      child: const Text("Add Session", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Active Sessions", style: TextStyle(fontWeight: FontWeight.bold, color: tealDark)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('active_sessions')
                .where('lecturerId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("No active sessions."));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _buildActiveSessionCard(docs[i].id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionCard(String docId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.sensors, color: Colors.green),
        title: Text("${data['courseCode']} - ${data['sessionType']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildActionButton(
                  title: "Take Attendance",
                  subtitle: "Start scanning now",
                  icon: Icons.qr_code_scanner,
                  color: tealPrimary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendancePage(
                    courseCode: data['courseCode'],
                    sessionType: data['sessionType'],
                  ))),
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  title: "Assign Invigilator",
                  subtitle: "Delegate to staff",
                  icon: Icons.person_add,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Assign())),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _endSession(docId),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("End & Remove Session", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ─── IMPROVED HISTORY TAB ────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('attendance')
        .where('lecturerId', isEqualTo: uid);

    query = query.orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                SizedBox(height: 10),
                Text("No attendance records found.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            String sType = d['sessionType'] ?? 'Class';

            // UI Color logic for session type
            Color typeColor = tealPrimary;
            if (sType == 'Lab') typeColor = Colors.purple;
            if (sType == 'Exam') typeColor = Colors.orange.shade800;

            return Card(
              elevation: 0.5,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewList(attendanceData: d))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Session Icon with dynamic color
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          sType == 'Exam' ? Icons.assignment : sType == 'Lab' ? Icons.science : Icons.school,
                          color: typeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['courseCode'] ?? 'Unknown Course',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(d['date'] ?? 'N/A', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(width: 12),
                                Icon(Icons.group, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text("${d['totalPresent']} Present", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Badge for Session Type
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sType.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({required String title, required String subtitle, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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