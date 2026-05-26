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

  const InvigilatorTakeAttendance({
    super.key,
    required this.courseCode,
    required this.sessionType,
    required this.venue,
    required this.date,
  });

  @override
  State<InvigilatorTakeAttendance> createState() => _InvigilatorTakeAttendanceState();
}

class _InvigilatorTakeAttendanceState extends State<InvigilatorTakeAttendance> {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  final List<Map<String, String>> _scannedStudents = [];

  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isProcessing = false;
  bool _isSubmitting = false;
  bool _isLoadingStudents = true;

  int _failedScanCount = 0;
  String? _lastFailedCode;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
    _loadCourseStudents();
  }

  Future<void> _fetchCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            _currentUserName = "${data?['name'] ?? ''} ${data?['surname'] ?? ''}".trim();
          });
        }
      }
    }
  }

  Future<void> _loadCourseStudents() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('students').get();
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
        _showSnack('3 failed attempts — opening manual search...', Colors.orange);
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

      // Find student in pre-loaded eligible list
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
            _scannedStudents.insert(0, student); // Recent on top
            _failedScanCount = 0;
            _lastFailedCode = null;
          });
          _showSnack('Captured: ${student['name']}', tealDark);
        }
      } else {
        _handleFailedScan(code);
        _showSnack('Student $code not registered for ${widget.courseCode}', Colors.red);
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
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
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
              if (!_scannedStudents.any((s) => s['regNo'] == student['regNo'])) {
                _scannedStudents.insert(0, student);
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
        title: const Text('Confirm Attendance', style: TextStyle(color: tealPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Submit attendance for ${widget.courseCode}?\n\nPresent: ${_scannedStudents.length}\nExpected: ${_allEligibleStudents.length}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: tealPrimary, elevation: 0),
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
    if (_currentUserName == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final Set<String> presentRegNos = _scannedStudents.map((s) => s['regNo']!.toUpperCase()).toSet();
      List<Map<String, dynamic>> fullAttendanceList = [];

      for (var student in _allEligibleStudents) {
        final String regNo = student['regNo'].toString();
        fullAttendanceList.add({
          'regNo': regNo,
          'name': student['name'] ?? 'Unknown',
          'surname': student['surname'] ?? '',
          'status': presentRegNos.contains(regNo.toUpperCase()) ? 'Present' : 'Absent',
        });
      }

      fullAttendanceList.sort((a, b) => b['status'].compareTo(a['status']));

      await FirebaseFirestore.instance.collection('attendance').add({
        'courseCode': widget.courseCode,
        'sessionType': widget.sessionType,
        'venue': widget.venue,
        'date': widget.date,
        'timestamp': FieldValue.serverTimestamp(),
        'submittedBy': _currentUserName,
        'fullAttendanceList': fullAttendanceList,
        'totalPresent': _scannedStudents.length,
        'totalEnrolled': _allEligibleStudents.length,
        'lecturerId': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        _showSnack('Attendance Saved Successfully', tealPrimary);
        Navigator.pop(context);
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
        title: const Text('AAS - INVIGILATOR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Info Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: tealLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('COURSE : ${widget.courseCode}',
                    style: const TextStyle(color: tealDark, fontWeight: FontWeight.bold, fontSize: 12)),
                Text('TYPE : ${widget.sessionType}',
                    style: const TextStyle(color: tealDark, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),

          // Scanner Section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.32,
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
                      Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Colors.white))),

                    // Scanned Count Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: tealPrimary, borderRadius: BorderRadius.circular(20)),
                        child: Text('SCANNED: ${_scannedStudents.length} / ${_allEligibleStudents.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recent Scans Header
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 15, 16, 8),
            child: Row(
                children: [
                  Text('RECENT SCANS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  Spacer()
                ]
            ),
          ),

          // List of Scanned Students
          Expanded(
            child: _scannedStudents.isEmpty
                ? Center(child: Text(_isLoadingStudents ? 'Loading Students...' : 'No students scanned yet', style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _scannedStudents.length,
              itemBuilder: (context, i) {
                final s = _scannedStudents[i];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: tealLight,
                      child: Icon(Icons.person, color: tealPrimary, size: 20),
                    ),
                    title: Text("${s['name']} ${s['surname']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(s['regNo']!, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: tealPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _goManual,
                    icon: const Icon(Icons.search, color: tealPrimary),
                    label: const Text('MANUAL SEARCH', style: TextStyle(color: tealPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: (_isSubmitting || _scannedStudents.isEmpty) ? null : _showConfirmDialog,
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SUBMIT LIST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}