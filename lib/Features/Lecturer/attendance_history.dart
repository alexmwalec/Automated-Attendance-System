import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
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

  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime(2000);
    return DateTime(2000);
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

  bool _isSessionLive(String startTimeStr, String endTimeStr) {
    try {
      final now = DateTime.now();
      final start = _parseTime(startTimeStr);
      final end = _parseTime(endTimeStr);
      final startDt =
          DateTime(now.year, now.month, now.day, start.hour, start.minute);
      final endDt =
          DateTime(now.year, now.month, now.day, end.hour, end.minute);
      return now.isAfter(startDt) && now.isBefore(endDt);
    } catch (e) {
      return false;
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

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87)),
      ],
    );
  }

  void _deleteSession(String docId, bool isAssignedTask) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Session",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            "Are you sure you want to delete this ${isAssignedTask ? 'assignment' : 'session'}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final collection =
                  isAssignedTask ? 'exam_assignments' : 'active_sessions';
              await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(docId)
                  .delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        title: const Text('Session Manager',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Manage Sessions"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManageTab(),
          _buildHistoryTab(),
        ],
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
          if (i == 0 || i == 1)
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => LecturerDashboard(initialIndex: i)),
                (r) => false);
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

    Stream<QuerySnapshot> manualSessions = FirebaseFirestore.instance
        .collection('active_sessions')
        .where('lecturerId', isEqualTo: uid)
        .snapshots();

    Stream<QuerySnapshot> assignedTasks = FirebaseFirestore.instance
        .collection('exam_assignments')
        .where('lecturerId', isEqualTo: uid)
        .snapshots();

    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: CombineLatestStream.list([manualSessions, assignedTasks])
          .map((snapshots) {
        List<QueryDocumentSnapshot> combined = [];
        for (var snap in snapshots) combined.addAll(snap.docs);
        combined.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          return _parseDateTime(bData['createdAt'])
              .compareTo(_parseDateTime(aData['createdAt']));
        });
        return combined;
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_off_outlined,
                    size: 64, color: tealPrimary.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text("No sessions or assignments found.",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final bool isAssignedTask =
                docs[i].reference.path.contains('exam_assignments');

            final String courseCode =
                data['courseCode'] ?? data['course'] ?? 'N/A';
            final String room = data['room'] ?? data['venue'] ?? 'Not Set';
            final String invigilator = data['invigilatorName'] ?? 'Self';
            final String time =
                data['time'] ?? "${data['startTime']} - ${data['endTime']}";

            bool isLive = false;
            if (!isAssignedTask) {
              isLive = _isSessionLive(
                  data['startTime'] ?? "", data['endTime'] ?? "");
            }

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Assign(
                    courseCode: courseCode,
                    sessionType: data['sessionType'] ?? '',
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tealPrimary.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tealLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.book_outlined,
                                color: tealPrimary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(courseCode,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey, size: 18),
                        ],
                      ),
                    ),
                    const Divider(
                        height: 1, thickness: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoCol("Venue", room),
                              _buildInfoCol("Time", time),
                              _buildInfoCol(
                                  "Type", data['sessionType'] ?? 'N/A'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text("Invigilato: $invigilator",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isLive ? "LIVE" : "SCHEDULED",
                                  style: TextStyle(
                                      color:
                                          isLive ? Colors.green : Colors.grey,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!isAssignedTask)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.redAccent),
                                  onPressed: () => _deleteSession(
                                      docs[i].id, isAssignedTask),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: tealPrimary),
                                onPressed: () => _showSessionDialog(
                                    docId: docs[i].id, existingData: data),
                              ),
                            ],
                          ),
                        ],
                      ),
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('lecturerId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
              child: Text("No records found.",
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: tealPrimary.withOpacity(0.2))),
              child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: tealLight,
                    child: Icon(Icons.history, color: tealPrimary)),
                title: Text("${data['courseCode']} - ${data['sessionType']}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${data['date']}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ViewList(attendanceData: data))),
              ),
            );
          },
        );
      },
    );
  }
}
