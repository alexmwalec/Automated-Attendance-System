import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class SubmitList extends StatelessWidget {
  final List<Map<String, String>> students;
  final String sessionType;
  final String courseCode;

  const SubmitList({
    super.key,
    required this.students,
    required this.sessionType,
    required this.courseCode,
  });

  Future<void> _submitToFirebase(BuildContext context) async {
    try {
      final studentQuery = await FirebaseFirestore.instance.collection('students').get();
      final presentRegNos = students.map((s) => s['regNo']).toSet();

      List<Map<String, dynamic>> fullAttendanceList = [];

      for (var doc in studentQuery.docs) {
        final data = doc.data();

        String regNo = data['regNo']?.toString() ?? '';
        String name = data['name']?.toString() ?? 'Unknown';
        String surname = data['surname']?.toString() ?? '';
        String studentStatus = data['status']?.toString() ?? 'Active';

        if (presentRegNos.contains(regNo)) {
          fullAttendanceList.add({
            'regNo': regNo,
            'name': name,
            'surname': surname,
            'status': 'Present',
          });
        } else if (studentStatus == 'Exit') {
          fullAttendanceList.add({
            'regNo': regNo,
            'name': name,
            'surname': surname,
            'status': 'Exit',
          });
        } else {
          fullAttendanceList.add({
            'regNo': regNo,
            'name': name,
            'surname': surname,
            'status': 'Absent',
          });
        }
      }


      final attendanceRecord = {
        'courseCode': courseCode,
        'sessionType': sessionType,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': 'lecturer_001',
        'fullAttendanceList': fullAttendanceList, // Store the combined list for history
        'totalPresent': students.length,
      };

      await FirebaseFirestore.instance
          .collection('attendance')
          .add(attendanceRecord);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance Confirmed!'),
            backgroundColor: tealDark,
          ),
        );
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Confirm Attendance',
            style: TextStyle(
                color: tealPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text(
            'Submit $sessionType attendance for $courseCode? This will automatically mark missing students as Absent or Exit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tealPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _submitToFirebase(context); // Start upload
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Confirm Attendance',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Container(
            color: tealLight,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(courseCode),
                  const SizedBox(width: 6),
                  _chip(sessionType),
                  const SizedBox(width: 6),
                  _chip(DateTime.now().toIso8601String().split('T')[0]),
                  const SizedBox(width: 6),
                  _chip('${students.length} Scanned'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFB2DFDB)),
          Container(
            color: tealLight,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: const Row(
              children: [
                _HeaderCell('Reg No', flex: 3),
                _HeaderCell('Name', flex: 4),
                _HeaderCell('Status', flex: 2),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFB2DFDB)),
          Expanded(
            child: students.isEmpty
                ? const Center(
              child: Text('No students scanned yet.',
                  style: TextStyle(color: tealDark, fontSize: 13)),
            )
                : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, i) {
                final s = students[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: Color(0xFFB2DFDB), width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(s['regNo'] ?? '',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black87)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text('${s['name']} ${s['surname']}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black87)),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text('Present',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tealDark)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed:
                students.isEmpty ? null : () => _showConfirmDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealPrimary,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                child: const Text('Confirm List',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: tealPrimary.withOpacity(0.4), width: 0.8),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w600, color: tealDark)),
  );
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.black87)),
    );
  }
}