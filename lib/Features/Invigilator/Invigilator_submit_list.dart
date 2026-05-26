import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class SubmitList extends StatefulWidget {
  final List<Map<String, String>> students;
  final String sessionType;
  final String courseCode;
  final String lecturerId;
  final String venue;
  final String date;

  const SubmitList({super.key, required this.students, required this.sessionType, required this.courseCode, required this.lecturerId, required this.venue, required this.date});

  @override
  State<SubmitList> createState() => _SubmitListState();
}

class _SubmitListState extends State<SubmitList> {
  bool _isSubmitting = false;

  Future<void> _submitToFirebase() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      final String invName = "${userDoc.data()?['name']} ${userDoc.data()?['surname']}".trim();

      // Get enrollment from course doc
      final courseDoc = await FirebaseFirestore.instance.collection('courses').doc(widget.courseCode).get();
      List<String> expectedRegNos = [];
      if (courseDoc.exists) {
        List<dynamic> raw = courseDoc.data()?['enrolledStudents'] ?? [];
        if (raw.isNotEmpty) expectedRegNos = raw[0].toString().split(',').map((e) => e.trim()).toList();
      }

      final presentRegNos = widget.students.map((s) => s['regNo']).toSet();
      List<Map<String, dynamic>> fullReport = [];

      for (String reg in expectedRegNos) {
        if (reg.isEmpty) continue;
        var sDoc = await FirebaseFirestore.instance.collection('students').doc(reg).get();
        fullReport.add({
          'regNo': reg,
          'name': sDoc.data()?['name'] ?? 'Unknown',
          'surname': sDoc.data()?['surname'] ?? '',
          'status': presentRegNos.contains(reg) ? 'Present' : 'Absent',
        });
      }

      await FirebaseFirestore.instance.collection('attendance').add({
        'courseCode': widget.courseCode,
        'sessionType': widget.sessionType,
        'venue': widget.venue,
        'date': widget.date,
        'timestamp': FieldValue.serverTimestamp(),
        'submittedBy': invName,
        'lecturerId': widget.lecturerId,
        'fullAttendanceList': fullReport,
        'totalPresent': widget.students.length,
        'totalExpected': expectedRegNos.length,
      });

      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(backgroundColor: tealPrimary, iconTheme: const IconThemeData(color: Colors.white), title: const Text('REVIEW LIST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.students.length,
              itemBuilder: (context, i) => ListTile(
                title: Text("${widget.students[i]['name']} ${widget.students[i]['surname']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(widget.students[i]['regNo']!, style: const TextStyle(fontSize: 11)),
                trailing: const Text('Present', style: TextStyle(color: tealDark, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: tealPrimary, minimumSize: const Size(double.infinity, 50)),
              onPressed: _isSubmitting ? null : _submitToFirebase,
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('CONFIRM & SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}