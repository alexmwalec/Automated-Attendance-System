import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manual_search.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class InvigilatorTakeAttendance extends StatefulWidget {
  final String courseCode;
  final String sessionType;
  final String venue;
  final String date;
  final String lecturerId;

  const InvigilatorTakeAttendance({
    super.key,
    required this.courseCode,
    required this.sessionType,
    required this.venue,
    required this.date,
    required this.lecturerId,
  });

  @override
  State<InvigilatorTakeAttendance> createState() =>
      _InvigilatorTakeAttendanceState();
}

class _InvigilatorTakeAttendanceState extends State<InvigilatorTakeAttendance> {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  final List<Map<String, String>> _scannedStudents = [];
  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isProcessing = false;
  bool _isLoadingStudents = true;
  bool _isSubmitting = false;
  int _totalEnrolled = 0;
  int _failedScanCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCourseStudents();
  }

  Future<void> _loadCourseStudents() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('students').get();
      final List<Map<String, dynamic>> filtered = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final String coursesString = data['courses']?.toString() ?? '';
        final List<String> courseList = coursesString
            .split(',')
            .map((e) => e.trim().toUpperCase())
            .toList();

        if (courseList.contains(widget.courseCode.trim().toUpperCase())) {
          filtered.add({'regNo': doc.id.trim(), ...data});
        }
      }
      if (mounted) {
        setState(() {
          _allEligibleStudents = filtered;
          _totalEnrolled = filtered.length;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isLoadingStudents) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim().toUpperCase();
      if (code == null || code.isEmpty) continue;

      setState(() => _isProcessing = true);
      final studentData = _allEligibleStudents.firstWhere(
        (s) => s['regNo'].toString().toUpperCase() == code,
        orElse: () => {},
      );

      if (studentData.isNotEmpty) {
        final student = {
          'regNo': studentData['regNo'].toString(),
          'name': studentData['name'].toString(),
          'surname': studentData['surname'].toString(),
        };
        if (!_scannedStudents.any((s) => s['regNo'] == student['regNo'])) {
          setState(() {
            _scannedStudents.insert(0, student);
            _failedScanCount = 0;
          });
          _showSnack('Captured: ${student['name']}', tealDark);
        }
      } else {
        _handleFailedScan(code);
      }
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _isProcessing = false);
      break;
    }
  }

  void _handleFailedScan(String code) {
    _failedScanCount++;
    if (_failedScanCount >= 3) {
      _failedScanCount = 0;
      _showSnack('3 failed attempts — open manual search', Colors.orange);
      _goManual();
    } else {
      _showSnack('Student not registered for this course', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2)));
  }

  void _goManual() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ManualSearch(
                  existingStudents: _scannedStudents,
                  onStudentAdded: (s) =>
                      setState(() => _scannedStudents.insert(0, s)),
                  courseCode: widget.courseCode,
                )));
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      final String invName =
          "${userDoc.data()?['name']} ${userDoc.data()?['surname']}".trim();

      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseCode)
          .get();
      List<String> expectedRegNos = [];
      if (courseDoc.exists) {
        List<dynamic> raw = courseDoc.data()?['enrolledStudents'] ?? [];
        if (raw.isNotEmpty) {
          expectedRegNos =
              raw[0].toString().split(',').map((e) => e.trim()).toList();
        }
      }

      final presentRegNos = _scannedStudents.map((s) => s['regNo']).toSet();
      List<Map<String, dynamic>> fullReport = [];

      for (String reg in expectedRegNos) {
        if (reg.isEmpty) continue;
        var sDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(reg)
            .get();
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
        'totalPresent': _scannedStudents.length,
        'totalExpected': expectedRegNos.length,
      });

      if (mounted) {
        _showSnack('Attendance Submitted Successfully', tealPrimary);
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: tealPrimary,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('CAPTURE ATTENDANCE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          // Info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: tealLight,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('COURSE: ${widget.courseCode}',
                      style: const TextStyle(
                          color: tealDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  Text('VENUE: ${widget.venue}',
                      style: const TextStyle(
                          color: tealDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ]),
          ),

          // Scanner Area
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.28,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tealPrimary, width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(children: [
                  MobileScanner(controller: _cameraCtrl, onDetect: _onDetect),
                  if (_isProcessing)
                    const Center(
                        child: CircularProgressIndicator(color: tealPrimary)),
                  Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: tealPrimary,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                              '${_scannedStudents.length} / $_totalEnrolled',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)))),
                ]),
              ),
            ),
          ),

          // Search bar below camera
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: GestureDetector(
              onTap: _goManual,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black12)),
                child: const Row(children: [
                  Icon(Icons.search, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text('Add student by searching reg number',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ),
            ),
          ),

          // Review list header
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('REVIEW SCANNED LIST',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)))),

          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                  color: tealLight, borderRadius: BorderRadius.circular(4)),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text('REG NO',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11))),
                  Expanded(
                      flex: 4,
                      child: Text('NAME',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11))),
                  Expanded(
                      flex: 2,
                      child: Text('STATUS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
            ),
          ),

          // Scanned students list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _scannedStudents.length,
              itemBuilder: (context, i) {
                final s = _scannedStudents[i];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black12, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text(s['regNo']!,
                              style: const TextStyle(fontSize: 11))),
                      Expanded(
                          flex: 4,
                          child: Text("${s['name']} ${s['surname']}",
                              style: const TextStyle(fontSize: 11))),
                      const Expanded(
                          flex: 2,
                          child: Text('Present',
                              style: TextStyle(
                                  color: tealDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11))),
                    ],
                  ),
                );
              },
            ),
          ),

          // Submit button only at the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: tealPrimary,
                  minimumSize: const Size(double.infinity, 44)),
              onPressed: (_scannedStudents.isEmpty || _isSubmitting)
                  ? null
                  : _submitAttendance,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('CONFIRM & SUBMIT',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
