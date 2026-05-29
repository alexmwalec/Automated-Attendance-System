import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manual_search.dart';
import 'attendance_state.dart';

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
  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isProcessing = false;
  bool _isLoadingStudents = true;
  bool _isSubmitting = false;
  int _totalEnrolled = 0;
  int _failedScanCount = 0;

  @override
  void initState() {
    super.initState();
    AttendanceState.clear();
    AttendanceState.markedStudents.addListener(_onMarkedStudentsChanged);
    _loadCourseStudents();
  }

  void _onMarkedStudentsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AttendanceState.markedStudents.removeListener(_onMarkedStudentsChanged);
    _cameraCtrl.dispose();
    super.dispose();
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
            'regNo': normalizeReg(doc.id),
            'originalRegNo': doc.id,
            ...data
          });
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
      String? code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) continue;

      setState(() => _isProcessing = true);

      final String normalizedCode = normalizeReg(code);
      debugPrint('Scanned: $code -> Normalized: $normalizedCode');

      final studentData = _allEligibleStudents.firstWhere(
        (s) => normalizeReg(s['regNo'].toString()) == normalizedCode,
        orElse: () => {},
      );

      if (studentData.isNotEmpty) {
        if (!AttendanceState.isMarked(normalizedCode)) {
          AttendanceState.addStudent({
            'regNo': normalizedCode,
            'name': studentData['name'].toString(),
            'surname': studentData['surname'].toString(),
          });
          _showSnack(
              'Captured: ${studentData['name']} ${studentData['surname']}',
              tealDark);
          _failedScanCount = 0;
        } else {
          _showSnack('$normalizedCode already marked!', Colors.orange);
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
    if (!mounted) return;
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
        builder: (_) => ManualSearch(courseCode: widget.courseCode),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    final scanned = AttendanceState.markedStudents.value;
    if (scanned.isEmpty) {
      _showSnack('No students marked for attendance', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('User not logged in', Colors.red);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final String invName =
          "${userDoc.data()?['name'] ?? ''} ${userDoc.data()?['surname'] ?? ''}"
              .trim();

      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseCode)
          .get();

      List<String> expectedRegNos = [];
      if (courseDoc.exists) {
        List<dynamic> raw = courseDoc.data()?['enrolledStudents'] ?? [];
        if (raw.isNotEmpty) {
          if (raw[0] is String) {
            expectedRegNos = raw[0]
                .toString()
                .split(',')
                .map((e) => normalizeReg(e))
                .toList();
          } else if (raw is List) {
            expectedRegNos =
                raw.map((e) => normalizeReg(e.toString())).toList();
          }
        }
      }

      if (expectedRegNos.isEmpty) {
        expectedRegNos = scanned.map((s) => s['regNo']!).toList();
      }

      final Set<String> presentRegNos =
          scanned.map((s) => normalizeReg(s['regNo']!)).toSet();

      List<Map<String, dynamic>> fullReport = [];

      for (String reg in expectedRegNos) {
        if (reg.isEmpty) continue;
        final String normalizedReg = normalizeReg(reg);
        final bool isPresent = presentRegNos.contains(normalizedReg);

        DocumentSnapshot studentDoc;
        try {
          studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(reg)
              .get();
          if (!studentDoc.exists) {
            studentDoc = await FirebaseFirestore.instance
                .collection('students')
                .doc(normalizedReg)
                .get();
          }
        } catch (e) {
          studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(normalizedReg)
              .get();
        }

        final studentData = studentDoc.data() as Map<String, dynamic>?;
        fullReport.add({
          'regNo': reg,
          'name': studentData?['name']?.toString() ?? 'Unknown',
          'surname': studentData?['surname']?.toString() ?? '',
          'status': isPresent ? 'Present' : 'Absent',
        });
      }

      for (String scannedReg in presentRegNos) {
        if (!expectedRegNos.map((e) => normalizeReg(e)).contains(scannedReg)) {
          DocumentSnapshot studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(scannedReg)
              .get();
          final studentData = studentDoc.data() as Map<String, dynamic>?;
          fullReport.add({
            'regNo': scannedReg,
            'name': studentData?['name']?.toString() ?? 'Unknown',
            'surname': studentData?['surname']?.toString() ?? '',
            'status': 'Present',
          });
        }
      }

      final attendanceData = {
        'courseCode': widget.courseCode,
        'sessionType': widget.sessionType,
        'venue': widget.venue,
        'date': (widget.date.isNotEmpty && widget.date != 'N/A')
            ? widget.date
            : DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'submittedBy': invName.isEmpty ? 'Invigilator' : invName,
        'invigilatorId': user.uid,
        'lecturerId': widget.lecturerId,
        'fullAttendanceList': fullReport,
        'totalPresent': scanned.length,
        'totalExpected': expectedRegNos.length,
        'presentRegNos': presentRegNos.toList(),
      };

      await FirebaseFirestore.instance
          .collection('attendance')
          .add(attendanceData);

      if (mounted) {
        _showSnack('Submitted! ${scanned.length} students marked present',
            tealPrimary);
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) _showSnack('Error submitting: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanned = AttendanceState.markedStudents.value;

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
                    Container(
                      color: Colors.black45,
                      child: const Center(
                          child: CircularProgressIndicator(color: tealPrimary)),
                    ),
                  if (_isLoadingStudents)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: tealPrimary),
                            SizedBox(height: 8),
                            Text('Loading students...',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: tealPrimary,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('${scanned.length} / $_totalEnrolled',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)))),
                ]),
              ),
            ),
          ),
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
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('REVIEW SCANNED LIST',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)))),
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
          Expanded(
            child: scanned.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No students scanned yet',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text('Scan QR codes or search manually',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    itemCount: scanned.length,
                    itemBuilder: (context, i) {
                      final s = scanned[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.black12, width: 0.5)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: tealPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
                onPressed: (scanned.isEmpty || _isSubmitting)
                    ? null
                    : _submitAttendance,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Attendance',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
