import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manual_search.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class AttendancePage extends StatefulWidget {
  final String courseCode;
  final String sessionType;

  const AttendancePage({
    super.key,
    required this.courseCode,
    required this.sessionType,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  final List<Map<String, String>> _scannedStudents = [];
  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isProcessing = false;
  bool _isSubmitting = false;
  bool _isLoadingStudents = true;

  int _totalEnrolled = 0;
  int _failedScanCount = 0;
  String? _lastFailedCode;

  late String _selectedSessionType;

  @override
  void initState() {
    super.initState();
    _selectedSessionType = widget.sessionType;
    _loadCourseStudents();
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
      debugPrint('Error loading students: $e');
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
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
      int remaining = 3 - _failedScanCount;
      _showSnack(
        'Scan failed ($remaining attempt${remaining == 1 ? '' : 's'} left before manual search)',
        Colors.red,
      );
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

        if (_scannedStudents.any((s) => s['regNo'] == student['regNo'])) {
          _showSnack('${student['regNo']} already marked!', Colors.orange);
        } else {
          setState(() {
            _scannedStudents.add(student);
            _failedScanCount = 0;
            _lastFailedCode = null;
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
        builder: (_) => ManualSearch(
          existingStudents: _scannedStudents,
          onStudentAdded: (student) {
            setState(() {
              if (!_scannedStudents
                  .any((s) => s['regNo'] == student['regNo'])) {
                _scannedStudents.add(student);
              }
            });
          },
          courseCode: widget.courseCode,
        ),
      ),
    ).then((_) => setState(() => _isProcessing = false));
  }

  void _showConfirmDialog() {
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
    setState(() => _isSubmitting = true);
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseCode)
          .get();
      if (!courseDoc.exists) throw Exception("Course not found");

      List<dynamic> rawEnrolled = courseDoc.data()?['enrolledStudents'] ?? [];
      List<String> expectedRegNos = [];

      if (rawEnrolled.isNotEmpty) {
        String allIds = rawEnrolled[0].toString();
        expectedRegNos = allIds.split(',').map((e) => e.trim()).toList();
      }

      final presentRegNos = _scannedStudents.map((s) => s['regNo']).toSet();
      List<Map<String, dynamic>> fullAttendanceList = [];

      for (String regNo in expectedRegNos) {
        if (regNo.isEmpty) continue;

        var sDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(regNo)
            .get();
        var sData = sDoc.data();

        fullAttendanceList.add({
          'regNo': regNo,
          'name': sData?['name'] ?? 'Unknown',
          'surname': sData?['surname'] ?? '',
          'status': presentRegNos.contains(regNo) ? 'Present' : 'Absent',
        });
      }

      await FirebaseFirestore.instance.collection('attendance').add({
        'courseCode': widget.courseCode,
        'sessionType': _selectedSessionType,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': uid,
        'fullAttendanceList': fullAttendanceList,
        'totalPresent': _scannedStudents.length,
        'totalExpected': expectedRegNos.length,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Attendance Saved Successfully'),
              backgroundColor: tealPrimary),
        );
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
        title: const Text(
          'AAS',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: tealLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COURSE : ${widget.courseCode}',
                  style: const TextStyle(
                      color: tealDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                Text(
                  'SESSION TYPE : $_selectedSessionType',
                  style: const TextStyle(
                      color: tealDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
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
                          '${_scannedStudents.length}/$_totalEnrolled scanned',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: GestureDetector(
              onTap: _goManual,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      'Add student by searching reg number',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: const [
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
          Expanded(
            child: _scannedStudents.isEmpty
                ? const SizedBox()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _scannedStudents.length,
                    itemBuilder: (context, index) {
                      final s = _scannedStudents[index];
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: (_scannedStudents.isEmpty || _isSubmitting)
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
                    : const Text(
                        'Confirm & Save',
                        style: TextStyle(
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
