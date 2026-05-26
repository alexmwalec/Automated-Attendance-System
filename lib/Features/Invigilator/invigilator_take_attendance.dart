import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final String lecturerId; // ADDED

  const InvigilatorTakeAttendance({
    super.key,
    required this.courseCode,
    required this.sessionType,
    required this.venue,
    required this.date,
    required this.lecturerId, // ADDED
  });

  @override
  State<InvigilatorTakeAttendance> createState() =>
      _InvigilatorTakeAttendanceState();
}

class _InvigilatorTakeAttendanceState extends State<InvigilatorTakeAttendance> {
  final MobileScannerController _cameraController = MobileScannerController();
  final List<Map<String, String>> _scannedStudents = [];

  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isLoadingStudents = true;
  String? _currentUserName;
  bool _isSubmitting = false;

  String? _lastScanned;
  Timer? _scanCooldown;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
    _loadCourseStudents();
  }

  Future<void> _fetchCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            _currentUserName =
                "${data?['name'] ?? ''} ${data?['surname'] ?? ''}".trim();
          });
        }
      }
    }
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
          filtered.add({
            'regNo': doc.id.trim(),
            ...data,
          });
        }
      }

      if (mounted) {
        setState(() {
          _allEligibleStudents = filtered;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _handleScan(String rawValue) async {
    final regNo = rawValue.trim().toUpperCase();
    if (_lastScanned == regNo) return;
    _lastScanned = regNo;
    _scanCooldown?.cancel();
    _scanCooldown =
        Timer(const Duration(seconds: 2), () => _lastScanned = null);

    if (_scannedStudents.any((s) => s['regNo']!.toUpperCase() == regNo)) {
      HapticFeedback.mediumImpact();
      _showSnack('$regNo already marked present', Colors.orange);
      return;
    }

    final studentData = _allEligibleStudents.firstWhere(
      (s) => s['regNo'].toString().toUpperCase() == regNo,
      orElse: () => {},
    );

    if (studentData.isEmpty) {
      HapticFeedback.heavyImpact();
      _showSnack(
          'Student $regNo not registered for ${widget.courseCode}', Colors.red);
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _scannedStudents.add({
        'regNo': studentData['regNo'].toString(),
        'name': studentData['name']?.toString() ?? 'Unknown',
        'surname': studentData['surname']?.toString() ?? '',
      });
    });
    _showSnack('✓ ${studentData['name']} marked present', tealDark);
  }

  Future<void> _submitToFirebase() async {
    if (_currentUserName == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final Set<String> presentRegNos =
          _scannedStudents.map((s) => s['regNo']!.trim().toUpperCase()).toSet();

      List<Map<String, dynamic>> fullAttendanceList = [];

      for (var student in _allEligibleStudents) {
        final String dbRegNo = student['regNo'].toString().trim();
        final bool isPresent = presentRegNos.contains(dbRegNo.toUpperCase());

        fullAttendanceList.add({
          'regNo': dbRegNo,
          'name': student['name'] ?? 'Unknown',
          'surname': student['surname'] ?? '',
          'status': isPresent ? 'Present' : 'Absent',
        });
      }

      fullAttendanceList.sort((a, b) => b['status'].compareTo(a['status']));

      await FirebaseFirestore.instance.collection('attendance').add({
        'courseCode': widget.courseCode,
        'sessionType': widget.sessionType,
        'venue': widget.venue,
        'date': widget.date,
        'timestamp': FieldValue.serverTimestamp(),
        'submittedBy':
            _currentUserName, // invigilator's name (kept for their records)
        'lecturerId': widget
            .lecturerId, // FIXED: lecturer's UID so it appears in their history
        'invigilatorId': FirebaseAuth
            .instance.currentUser?.uid, // invigilator's UID for audit
        'fullAttendanceList': fullAttendanceList,
        'totalPresent': _scannedStudents.length,
        'totalEnrolled': _allEligibleStudents.length,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Attendance submitted!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        title: const Text('Capture Attendance',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _cameraController,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  if (barcode.rawValue != null) _handleScan(barcode.rawValue!);
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(
                  "Scanned: ${_scannedStudents.length} / ${_allEligibleStudents.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: tealDark),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealPrimary,
                      padding: const EdgeInsets.all(15),
                    ),
                    onPressed: _isSubmitting ? null : _submitToFirebase,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Attendance",
                            style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
