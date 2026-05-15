import 'package:firebase_auth/firebase_auth.dart';
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
      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      // 1. Get official enrollment for this course
      final courseDoc = await FirebaseFirestore.instance.collection('courses').doc(courseCode).get();
      if (!courseDoc.exists) throw Exception("Course not found");

      List<dynamic> expectedRegNos = courseDoc.data()?['enrolledStudents'] ?? [];
      final presentRegNos = students.map((s) => s['regNo']).toSet();

      List<Map<String, dynamic>> fullAttendanceList = [];

      // 2. Build the full report by fetching Name/Surname from 'students' collection
      for (String regNo in expectedRegNos) {
        // Fetch specific student metadata
        var sDoc = await FirebaseFirestore.instance.collection('students').doc(regNo).get();
        var sData = sDoc.data();

        fullAttendanceList.add({
          'regNo': regNo,
          'name': sData?['name'] ?? 'Unknown',
          'surname': sData?['surname'] ?? '',
          'status': presentRegNos.contains(regNo) ? 'Present' : 'Absent',
        });
      }

      // 3. Save the comprehensive record to 'attendance'
      await FirebaseFirestore.instance.collection('attendance').add({
        'courseCode': courseCode,
        'sessionType': sessionType,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': uid,
        'fullAttendanceList': fullAttendanceList, // Now contains Name & Surname
        'totalPresent': students.length,
        'totalExpected': expectedRegNos.length,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance Saved Successfully')));
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Confirm Attendance',
            style: TextStyle(color: tealPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text(
            'Submit $sessionType attendance for $courseCode?\n\nThis will compare scanned students against the official course list and mark missing students as Absent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tealPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              _submitToFirebase(context);
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
        title: const Text('Review Scanned List',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                _HeaderCell('Name & Surname', flex: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFB2DFDB), width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(s['regNo'] ?? '', style: const TextStyle(fontSize: 10))),
                      Expanded(flex: 4, child: Text('${s['name']} ${s['surname']}', style: const TextStyle(fontSize: 10))),
                      const Expanded(flex: 2, child: Text('Present', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tealDark))),
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
                onPressed: students.isEmpty ? null : () => _showConfirmDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Confirm & Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      border: Border.all(color: tealPrimary.withOpacity(0.4)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tealDark)),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
    );
  }
}