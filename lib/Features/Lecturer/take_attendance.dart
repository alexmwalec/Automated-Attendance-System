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

class AttendancePage extends StatefulWidget {
  final String courseCode;
  final String sessionType;
  final String room;

  const AttendancePage({
    super.key,
    required this.courseCode,
    required this.sessionType,
    required this.room,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isProcessing = false;
  bool _isLoadingStudents = true;
  bool _isSubmitting = false;
  bool _alreadyTaken = false;

  int _totalEnrolled = 0;
  int _failedScanCount = 0;
  String? _lastFailedCode;

  late String _selectedSessionType;

  @override
  void initState() {
    super.initState();
    _selectedSessionType = widget.sessionType;
    // Clear any previous session state
    AttendanceState.clear();
    AttendanceState.markedStudents.addListener(_onMarkedStudentsChanged);
    _loadCourseStudents();
    _checkIfAlreadyTaken();
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

  Future<void> _checkIfAlreadyTaken() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final snap = await FirebaseFirestore.instance
        .collection('attendance')
        .where('courseCode', isEqualTo: widget.courseCode)
        .where('sessionType', isEqualTo: widget.sessionType)
        .where('room', isEqualTo: widget.room)
        .where('date', isEqualTo: today)
        .get();

    if (snap.docs.isNotEmpty) {
      if (mounted) setState(() => _alreadyTaken = true);
    }
  }

  Future<void> _loadCourseStudents() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('students').get();

      final List<Map<String, dynamic>> filtered = [];
      for (var doc in snapshot.docs) {
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
            ...data,
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
      debugPrint('Error loading students: $e');
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  void _handleFailedScan(String code) {
    if (_lastFailedCode != code) {
      _lastFailedCode = code;
      _failedScanCount = 1;
    } else {
      _failedScanCount++;
    }

    if (_failedScanCount >= 3) {
      _failedScanCount = 0;
      _lastFailedCode = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnack(
            '3 failed attempts — opening manual search...', Colors.orange);
        Future.delayed(const Duration(milliseconds: 800), _goManual);
      });
    } else {
      final int remaining = 3 - _failedScanCount;
      _showSnack(
        'Student not registered for this course ($remaining attempt${remaining == 1 ? '' : 's'} left)',
        Colors.red,
      );
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isLoadingStudents || _alreadyTaken) return;
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
          _lastFailedCode = null;
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

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 2)),
    );
  }

  void _goManual() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualSearch(courseCode: widget.courseCode),
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  void _showConfirmDialog() {
    final scanned = AttendanceState.markedStudents.value;
    if (scanned.isEmpty) {
      _showSnack('No students marked for attendance', Colors.orange);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(
          'Confirm Attendance',
          style: TextStyle(
              color: tealPrimary, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Text(
            'Submit $_selectedSessionType attendance for ${widget.courseCode}?'),
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
              Navigator.pop(context);
              _submitToFirebase();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitToFirebase() async {
    final scanned = AttendanceState.markedStudents.value;
    if (scanned.isEmpty) {
      _showSnack('No students marked for attendance', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseCode)
          .get();
      if (!courseDoc.exists) throw Exception('Course not found');

      List<dynamic> rawEnrolled = courseDoc.data()?['enrolledStudents'] ?? [];
      List<String> expectedRegNos = [];

      if (rawEnrolled.isNotEmpty) {
        if (rawEnrolled[0] is String &&
            rawEnrolled[0].toString().contains(',')) {
          // Stored as a single comma-separated string in index 0
          expectedRegNos = rawEnrolled[0]
              .toString()
              .split(',')
              .map((e) => normalizeReg(e))
              .toList()
              .cast<String>();
        } else {
          // Stored as a proper list of strings
          expectedRegNos = rawEnrolled
              .map((e) => normalizeReg(e.toString()))
              .toList()
              .cast<String>();
        }
      }

      // Fall back to scanned list if course enrollment is empty
      if (expectedRegNos.isEmpty) {
        expectedRegNos = scanned.map((s) => s['regNo']!).toList();
      }

      final Set<String> presentRegNos =
          scanned.map((s) => normalizeReg(s['regNo']!)).toSet();

      List<Map<String, dynamic>> fullAttendanceList = [];

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
        } catch (_) {
          studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(normalizedReg)
              .get();
        }

        final studentData = studentDoc.data() as Map<String, dynamic>?;
        fullAttendanceList.add({
          'regNo': reg,
          'name': studentData?['name']?.toString() ?? 'Unknown',
          'surname': studentData?['surname']?.toString() ?? '',
          'status': isPresent ? 'Present' : 'Absent',
        });
      }

      // Add any scanned students not in the expected list
      for (final scannedReg in presentRegNos) {
        if (!expectedRegNos.map(normalizeReg).contains(scannedReg)) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(scannedReg)
              .get();
          final studentData = studentDoc.data() as Map<String, dynamic>?;
          fullAttendanceList.add({
            'regNo': scannedReg,
            'name': studentData?['name']?.toString() ?? 'Unknown',
            'surname': studentData?['surname']?.toString() ?? '',
            'status': 'Present',
          });
        }
      }

      await FirebaseFirestore.instance.collection('attendance').add({
        'courseCode': widget.courseCode,
        'sessionType': _selectedSessionType,
        'room': widget.room,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': uid,
        'fullAttendanceList': fullAttendanceList,
        'totalPresent': scanned.length,
        'totalExpected': expectedRegNos.length,
        'presentRegNos': presentRegNos.toList(),
      });

      if (mounted) {
        _showSnack(
            'Attendance Saved! ${scanned.length} students marked present',
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
        title: const Text(
          'AAS',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ── Info bar ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: tealLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COURSE: ${widget.courseCode}',
                  style: const TextStyle(
                      color: tealDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                Text(
                  'SESSION: $_selectedSessionType',
                  style: const TextStyle(
                      color: tealDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Scanner ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.30,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tealPrimary, width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    MobileScanner(controller: _cameraCtrl, onDetect: _onDetect),
                    if (_alreadyTaken)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'ATTENDANCE ALREADY TAKEN',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                            child:
                                CircularProgressIndicator(color: tealPrimary)),
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
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: tealPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${scanned.length} / $_totalEnrolled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Manual search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: GestureDetector(
              onTap: _alreadyTaken ? null : _goManual,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _alreadyTaken ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _alreadyTaken
                          ? 'Attendance already recorded for today'
                          : 'Add student by searching reg number',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Table header ──
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('REG NO',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: tealDark)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('FULL NAME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: tealDark)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('STATUS',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: tealDark)),
                ),
              ],
            ),
          ),
          const Divider(height: 8),

          // ── Scanned list ──
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
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: scanned.length,
                    itemBuilder: (context, index) {
                      final s = scanned[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(s['regNo'] ?? '',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('${s['name']} ${s['surname']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text('Present',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: tealPrimary,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ── Submit button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: (scanned.isEmpty || _isSubmitting || _alreadyTaken)
                    ? null
                    : _showConfirmDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealPrimary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _alreadyTaken ? 'Already Saved' : 'Confirm & Save',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner, size: 24), label: 'Scanner'),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
      ),
    );
  }
}
