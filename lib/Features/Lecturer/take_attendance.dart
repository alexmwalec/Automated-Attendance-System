import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:automated_attendance_system/constants.dart';
import 'manual_search.dart';
import 'submit_list.dart';

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
  bool _isProcessing = false;

  late String _selectedSessionType;
  final List<String> _sessionTypes = ['Class', 'Lab', 'Exam'];

  // ── Failed scan tracking ─────────────────────────────────────────────────
  // Maps a scanned code → how many times it has failed
  final Map<String, int> _failedScanCount = {};

  @override
  void initState() {
    super.initState();
    _selectedSessionType = widget.sessionType;
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null || code.isEmpty) continue;

      setState(() => _isProcessing = true);

      try {
        var studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(code)
            .get();

        if (studentDoc.exists) {
          final data = studentDoc.data()!;
          List<dynamic> enrolledCourses = data['courses'] ?? [];

          if (enrolledCourses.contains(widget.courseCode)) {
            // ── SUCCESS: student is enrolled ──────────────────────────────
            final student = {
              'regNo': data['regNo'].toString(),
              'name': data['name'].toString(),
              'surname': data['surname'].toString(),
            };

            // Clear any previous failure count for this code on success
            _failedScanCount.remove(code);

            if (_scannedStudents.any((s) => s['regNo'] == student['regNo'])) {
              _showSnack('${student['regNo']} already marked!', Colors.orange);
            } else {
              setState(() => _scannedStudents.add(student));
              _showSnack('Captured: ${student['name']}', tealDark);
            }
          } else {
            // ── FAIL: student not enrolled in this course ─────────────────
            _recordFailedScan(
              code,
              'Student not registered for ${widget.courseCode}',
            );
          }
        } else {
          // ── FAIL: student document not found ─────────────────────────────
          _recordFailedScan(code, 'Student $code not found');
        }
      } catch (e) {
        _showSnack('Error: $e', Colors.red);
      }

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _isProcessing = false);
      break;
    }
  }

  /// Records a failed scan for [code]. On the 3rd failure, automatically
  /// opens the manual search page and resets the counter for that code.
  void _recordFailedScan(String code, String snackMessage) {
    final count = (_failedScanCount[code] ?? 0) + 1;
    _failedScanCount[code] = count;

    if (count >= 3) {
      // Reset counter so repeated scan attempts start fresh
      _failedScanCount.remove(code);
      _showSnack(
        'Scan failed 3 times for "$code". Opening manual search...',
        Colors.orange,
      );
      // Small delay so the snackbar is visible before navigation
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _goManual(prefillCode: code);
      });
    } else {
      _showSnack('$snackMessage (attempt $count/3)', Colors.red);
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

  /// Opens the manual search page. If [prefillCode] is supplied it is passed
  /// through so ManualSearch can pre-populate the search field if it supports it.
  void _goManual({String? prefillCode}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AAS Attendance',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(widget.courseCode,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tealPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tealPrimary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book, color: tealPrimary),
                  const SizedBox(width: 10),
                  Text(
                    "Recording for: ${widget.courseCode}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: tealDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Session Type Selector
            const Text("Session Type",
                style: TextStyle(fontWeight: FontWeight.bold, color: tealDark)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _sessionTypes.map((type) {
                bool isSelected = _selectedSessionType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: tealPrimary,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black),
                  onSelected: (val) {
                    if (val) setState(() => _selectedSessionType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Scanner View
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tealPrimary, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
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
                    // ── Failed scan counter badge ─────────────────────────
                    if (_failedScanCount.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Failed: ${_failedScanCount.values.fold(0, (a, b) => a + b)}/3',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _goManual(),
                icon: const Icon(Icons.person_search, color: tealPrimary),
                label: const Text('Add Student Manually',
                    style: TextStyle(color: tealPrimary)),
              ),
            ),
            const SizedBox(height: 16),

            // Session Count Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                tileColor: Colors.white,
                leading: const Icon(Icons.group, color: tealPrimary),
                title: Text("${_scannedStudents.length} Students Scanned",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Selected Course: ${widget.courseCode}"),
                trailing: Text(_selectedSessionType,
                    style: const TextStyle(
                        color: tealPrimary, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pop(context);
          if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubmitList(
                  students: _scannedStudents,
                  sessionType: _selectedSessionType,
                  courseCode: widget.courseCode,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle), label: 'Confirm'),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
      ),
    );
  }
}
