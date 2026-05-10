import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Shared colours ────────────────────────────────────────────────────────
const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

// ══════════════════════════════════════════════════════════════════════════════
// InvigilatorAttendanceList
// Fetches the assigned course from exam_assignments (same source as the home
// screen) and then streams attendance records for that course from the
// attendance collection – exactly the same collection SubmitList writes to.
// ══════════════════════════════════════════════════════════════════════════════
class InvigilatorAttendanceList extends StatelessWidget {
  const InvigilatorAttendanceList({super.key});

  @override
  Widget build(BuildContext context) {
    // Step 1: get the assigned course code
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exam_assignments')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, assignSnap) {
        if (assignSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: tealLight,
            body: Center(child: CircularProgressIndicator(color: tealPrimary)),
          );
        }

        final String assignedCourse =
            (assignSnap.hasData && assignSnap.data!.docs.isNotEmpty)
                ? ((assignSnap.data!.docs.first.data()
                        as Map<String, dynamic>)['course'] ??
                    '')
                : '';

        return Scaffold(
          backgroundColor: tealLight,
          appBar: AppBar(
            backgroundColor: tealPrimary,
            automaticallyImplyLeading: false,
            title: Text(
              assignedCourse.isEmpty
                  ? 'Attendance List'
                  : 'Attendance – $assignedCourse',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: assignedCourse.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No exam assignment found.\nAttendance records will appear here once you have been assigned an exam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: tealDark),
                    ),
                  ),
                )
              // Step 2: stream attendance records for this course
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('attendance')
                      .where('courseCode', isEqualTo: assignedCourse)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, attSnap) {
                    if (attSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: tealPrimary));
                    }

                    if (!attSnap.hasData || attSnap.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No attendance records yet for this course.',
                          style: TextStyle(color: tealDark, fontSize: 14),
                        ),
                      );
                    }

                    final docs = attSnap.data!.docs;

                    // Show a list of sessions; tap to expand the full list
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _SessionCard(attendanceData: data);
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

// ── A card for each attendance session ───────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const _SessionCard({required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    final String courseCode = attendanceData['courseCode'] ?? 'N/A';
    final String sessionType = attendanceData['sessionType'] ?? 'N/A';
    final String date = attendanceData['date'] ?? 'N/A';
    final int totalPresent = attendanceData['totalPresent'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: tealPrimary.withOpacity(0.1),
          child: const Icon(Icons.assignment_turned_in, color: tealPrimary),
        ),
        title: Text(
          '$courseCode – $sessionType',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: tealDark),
        ),
        subtitle: Text('$date  •  $totalPresent present',
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: tealPrimary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _AttendanceDetailPage(attendanceData: attendanceData),
          ),
        ),
      ),
    );
  }
}

// ── Full detail view (mirrors ViewList from view_list.dart) ──────────────────
class _AttendanceDetailPage extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const _AttendanceDetailPage({required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    final List fullList = attendanceData['fullAttendanceList'] ?? [];

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Attendance Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailBox(attendanceData['sessionType'] ?? 'N/A'),
                _detailBox(attendanceData['courseCode'] ?? 'N/A'),
                _detailBox(attendanceData['date'] ?? 'N/A'),
                _detailBox('${attendanceData['totalPresent'] ?? 0} Present'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: tealPrimary, thickness: 4),
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: fullList.length,
              itemBuilder: (context, index) {
                final student = fullList[index];
                final String regNo = student['regNo']?.toString() ?? 'N/A';
                final String firstName =
                    student['name']?.toString() ?? 'Unknown';
                final String lastName = student['surname']?.toString() ?? '';
                final String status = student['status']?.toString() ?? 'Absent';

                Widget statusWidget;
                if (status == 'Present') {
                  statusWidget = const Text('Present',
                      style: TextStyle(
                          fontSize: 10,
                          color: tealDark,
                          fontWeight: FontWeight.bold));
                } else if (status == 'Exit') {
                  statusWidget = const Text('E',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold));
                } else {
                  statusWidget = const Text('Absent',
                      style: TextStyle(fontSize: 10, color: Colors.red));
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black12, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text(regNo,
                              style: const TextStyle(fontSize: 10))),
                      Expanded(
                          flex: 4,
                          child: Text('$firstName $lastName',
                              style: const TextStyle(fontSize: 10))),
                      Expanded(flex: 2, child: statusWidget),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating CSV Report...')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: tealPrimary),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Download CSV',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tealPrimary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: tealDark),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.teal.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText('REG NO')),
          Expanded(flex: 4, child: _headerText('FULL NAME')),
          Expanded(flex: 2, child: _headerText('STATUS')),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 11, color: tealDark));
  }
}
