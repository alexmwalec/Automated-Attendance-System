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

class _AttendanceHistoryState extends State<AttendanceHistory> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _currentIndex = 2;
  List<String> assignedCourses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide FAB based on tab index
    });
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

  // Helper to convert Firestore string "08:30 AM" back to TimeOfDay for editing
  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final ampm = parts[1].toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  void _showSessionDialog({String? docId, Map<String, dynamic>? existingData}) {
    String? selCourse = existingData?['courseCode'];
    String? selType = existingData?['sessionType'];
    TimeOfDay startTime = existingData != null
        ? _parseTime(existingData['startTime'])
        : TimeOfDay.now();
    TimeOfDay endTime = existingData != null
        ? _parseTime(existingData['endTime'])
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(docId == null ? "Create Active Session" : "Edit Active Session",
              style: const TextStyle(color: tealPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Select Course"),
                value: selCourse,
                items: assignedCourses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setDialogState(() => selCourse = v),
              ),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Session Type"),
                value: selType,
                items: ["Class", "Lab", "Exam"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setDialogState(() => selType = v),
              ),
              ListTile(
                title: Text("Start: ${startTime.format(context)}"),
                trailing: const Icon(Icons.access_time, size: 20),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: startTime);
                  if (t != null) setDialogState(() => startTime = t);
                },
              ),
              ListTile(
                title: Text("End: ${endTime.format(context)}"),
                trailing: const Icon(Icons.access_time, size: 20),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: endTime);
                  if (t != null) setDialogState(() => endTime = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: tealPrimary),
              onPressed: (selCourse == null || selType == null) ? null : () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final data = {
                  'lecturerId': uid,
                  'courseCode': selCourse,
                  'sessionType': selType,
                  'startTime': startTime.format(context),
                  'endTime': endTime.format(context),
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (docId == null) {
                  data['createdAt'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance.collection('active_sessions').add(data);
                } else {
                  await FirebaseFirestore.instance.collection('active_sessions').doc(docId).update(data);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: Text(docId == null ? "Create" : "Update", style: const TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
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
          tabs: const [Tab(text: "Manage Sessions"), Tab(text: "History")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildManageTab(), _buildHistoryTab()],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
        backgroundColor: tealPrimary,
        onPressed: () => _showSessionDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 0 || i == 1) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LecturerDashboard(initialIndex: i)), (r) => false);
          if (i == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Assign()));
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Manager'),
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('active_sessions').where('lecturerId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No active sessions."));

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.timer, color: tealPrimary),
                title: Text("${data['courseCode']} (${data['sessionType']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Time: ${data['startTime']} - ${data['endTime']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: tealPrimary, size: 20),
                      onPressed: () => _showSessionDialog(docId: docs[i].id, existingData: data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => FirebaseFirestore.instance.collection('active_sessions').doc(docs[i].id).delete(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('attendance').where('lecturerId', isEqualTo: uid).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text("${d['courseCode']} - ${d['sessionType']}"),
                subtitle: Text("Date: ${d['date']}"),
                trailing: const Icon(Icons.visibility, color: tealPrimary),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewList(attendanceData: d))),
              ),
            );
          },
        );
      },
    );
  }
}