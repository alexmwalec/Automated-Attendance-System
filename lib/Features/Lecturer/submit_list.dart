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
      // 1. Prepare the record
      final attendanceRecord = {
        'courseCode': courseCode,
        'sessionType': sessionType,
        'date': DateTime.now().toIso8601String().split('T')[0], // e.g. 2024-05-02
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': 'lecturer_001', // Ideally from your Auth state
        'presentStudents': students,
        'totalPresent': students.length,
      };

      // 2. Add to Firestore
      await FirebaseFirestore.instance
          .collection('attendance')
          .add(attendanceRecord);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance submitted to Firebase!'),
            backgroundColor: tealDark,
          ),
        );
        // Return to the first screen (Dashboard)
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
        title: const Text('Submit Attendance',
            style: TextStyle(
                color: tealPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text(
            'Submit $sessionType attendance for $courseCode with ${students.length} students?'),
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
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
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
          // Dynamic Session info chips
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
                  _chip('${students.length} Students'),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFB2DFDB)),

          // Table header
          Container(
            color: tealLight,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: const Row(
              children: [
                _HeaderCell('REG NO', flex: 3),
                _HeaderCell('NAME', flex: 2),
                _HeaderCell('SURNAME', flex: 2),
                _HeaderCell('STATUS', flex: 2),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFB2DFDB)),

          // Rows
          Expanded(
            child: students.isEmpty
                ? const Center(
              child: Text('No students added yet.',
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
                                fontSize: 9.5, color: Colors.black87)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(s['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 9.5, color: Colors.black87)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(s['surname'] ?? '',
                            style: const TextStyle(
                                fontSize: 9.5, color: Colors.black87)),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text('Present',
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: tealDark)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Submit button
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
                child: const Text('Submit List',
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
              color: Colors.black87,
              letterSpacing: 0.3)),
    );
  }
}