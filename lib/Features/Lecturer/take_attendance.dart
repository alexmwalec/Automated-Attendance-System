import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manual_search.dart';
import 'submit_list.dart';

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
  bool _isProcessing = false;

  int _failedScanCount = 0;
  String? _lastFailedCode;

  late String _selectedSessionType;

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
          List<dynamic> enrolledCourses =
              data['courses'] ?? []; // Array of strings in Firestore

          // VALIDATION: Is student registered for THIS course?
          if (enrolledCourses.contains(widget.courseCode)) {
            final student = {
              'regNo': data['regNo'].toString(),
              'name': data['name'].toString(),
              'surname': data['surname'].toString(),
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
            _showSnack(
                'Student not registered for ${widget.courseCode}', Colors.red);
          }
        } else {
          _handleFailedScan(code);
          _showSnack('Student $code not found', Colors.red);
        }
      } catch (e) {
        _showSnack('Error: $e', Colors.red);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Info bar: separate from header, flush to it ──
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

          // ── Camera box: same width as info bar, fixed proportion ──
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
                  ],
                ),
              ),
            ),
          ),

          // ── Manual search bar: right below the camera ──
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

          const SizedBox(height: 16),

          // ── Table header ──
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

          // ── Scanned students list ──
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
        ],
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
