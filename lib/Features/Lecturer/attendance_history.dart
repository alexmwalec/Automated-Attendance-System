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

class _AttendanceHistoryState extends State<AttendanceHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _currentIndex = 2;
  List<String> assignedCourses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchAssignedCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssignedCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    var doc =
        await FirebaseFirestore.instance.collection('lecturers').doc(uid).get();
    if (doc.exists) {
      List<dynamic> rawList = doc.data()?['assignedCourses'] ?? [];
      List<String> codes = [];
      for (var item in rawList) {
        String val = item.toString();
        val.contains(',')
            ? codes.addAll(val.split(',').map((e) => e.trim()))
            : codes.add(val.trim());
      }
      setState(() => assignedCourses = codes);
    }
  }

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
              docId == null ? "Create Active Session" : "Edit Active Session",
              style: const TextStyle(color: tealPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Select Course"),
                value: selCourse,
                items: assignedCourses
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selCourse = v),
              ),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Session Type"),
                value: selType,
                items: ["Class", "Lab", "Exam"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selType = v),
              ),
              ListTile(
                title: Text("Start: ${startTime.format(context)}"),
                trailing: const Icon(Icons.access_time, size: 20),
                onTap: () async {
                  final t = await showTimePicker(
                      context: context, initialTime: startTime);
                  if (t != null) setDialogState(() => startTime = t);
                },
              ),
              ListTile(
                title: Text("End: ${endTime.format(context)}"),
                trailing: const Icon(Icons.access_time, size: 20),
                onTap: () async {
                  final t = await showTimePicker(
                      context: context, initialTime: endTime);
                  if (t != null) setDialogState(() => endTime = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: tealPrimary),
              onPressed: (selCourse == null || selType == null)
                  ? null
                  : () async {
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
                        await FirebaseFirestore.instance
                            .collection('active_sessions')
                            .add(data);
                      } else {
                        await FirebaseFirestore.instance
                            .collection('active_sessions')
                            .doc(docId)
                            .update(data);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(docId == null ? "Create" : "Update",
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isManageTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
    tealLight automaticallyImplyLeading: false,
        backgroundColor: tealPrimary,
        elevation: 2,
        shadowColor: tealDark.withOpacity(0.4),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'AAS PORTAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'SESSION MANAGER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: tealPrimary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.zero,
              tabs: [
                Tab(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isManageTab ? FontWeight.w800 : FontWeight.w400,
                      color: isManageTab ? tealPrimary : Colors.black45,
                    ),
                    child: const Text('Manage Sessions'),
                  ),
                ),
                Tab(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          !isManageTab ? FontWeight.w800 : FontWeight.w400,
                      color: !isManageTab ? tealPrimary : Colors.black45,
                    ),
                    child: const Text('History'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildManageTab(), _buildHistoryTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: isManageTab
          ? FloatingActionButton(
              backgroundColor: tealPrimary,
              shape: const CircleBorder(),
              onPressed: () => _showSessionDialog(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 0 || i == 1) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => LecturerDashboard(initialIndex: i)),
                (r) => false);
          }
          if (i == 3) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const Assign()));
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Attendance'),
          BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts), label: 'Manager'),
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('active_sessions')
          .where('lecturerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: tealPrimary));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No active sessions.", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tealPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_outlined, color: tealPrimary),
                ),
                title: Text(
                  data['courseCode'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['sessionType'] ?? 'Class', style: const TextStyle(color: tealDark, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("${data['startTime']} - ${data['endTime']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: tealPrimary),
                      onPressed: () => _showSessionDialog(docId: docs[i].id, existingData: data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('lecturerId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: tealPrimary));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No attendance history found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ViewList(attendanceData: data)),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tealPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_edu, color: tealPrimary),
                ),
                title: Text(
                  "${data['courseCode']} - ${data['sessionType']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  "Date: ${data['date']}\nBy: ${data['submittedBy'] ?? 'N/A'}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${data['totalPresent']} Present",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: tealPrimary),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
