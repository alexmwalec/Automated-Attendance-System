import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manual_search.dart';
import 'Invigilator_submit_list.dart';

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
  State<InvigilatorTakeAttendance> createState() => _InvigilatorTakeAttendanceState();
}

class _InvigilatorTakeAttendanceState extends State<InvigilatorTakeAttendance> {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  final List<Map<String, String>> _scannedStudents = [];
  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isProcessing = false;
  bool _isLoadingStudents = true;
  int _totalEnrolled = 0;
  int _failedScanCount = 0;
  String? _lastFailedCode;

  @override
  void initState() {
    super.initState();
    _loadCourseStudents();
  }

  Future<void> _loadCourseStudents() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('students').get();
      final List<Map<String, dynamic>> filtered = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final String coursesString = data['courses']?.toString() ?? '';
        final List<String> courseList = coursesString.split(',').map((e) => e.trim().toUpperCase()).toList();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _goManual() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ManualSearch(
      existingStudents: _scannedStudents,
      onStudentAdded: (s) => setState(() => _scannedStudents.insert(0, s)),
      courseCode: widget.courseCode,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: tealPrimary, elevation: 0, iconTheme: const IconThemeData(color: Colors.white), title: const Text('CAPTURE ATTENDANCE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), color: tealLight,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('COURSE: ${widget.courseCode}', style: const TextStyle(color: tealDark, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('VENUE: ${widget.venue}', style: const TextStyle(color: tealDark, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3, width: double.infinity,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: tealPrimary, width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(children: [
                  MobileScanner(controller: _cameraCtrl, onDetect: _onDetect),
                  Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: tealPrimary, borderRadius: BorderRadius.circular(20)), child: Text('${_scannedStudents.length} / $_totalEnrolled', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                ]),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Align(alignment: Alignment.centerLeft, child: Text('RECENT SCANS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _scannedStudents.length,
              itemBuilder: (context, i) => Card(
                elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(leading: const CircleAvatar(backgroundColor: tealLight, child: Icon(Icons.person, color: tealPrimary)), title: Text("${_scannedStudents[i]['name']} ${_scannedStudents[i]['surname']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(_scannedStudents[i]['regNo']!, style: const TextStyle(fontSize: 12)), trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: tealPrimary)), onPressed: _goManual, child: const Text('MANUAL SEARCH', style: TextStyle(color: tealPrimary, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: tealPrimary), onPressed: _scannedStudents.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitList(students: _scannedStudents, sessionType: widget.sessionType, courseCode: widget.courseCode, lecturerId: widget.lecturerId, venue: widget.venue, date: widget.date))), child: const Text('REVIEW & SUBMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            ]),
          ),
        ],
      ),
    );
  }
}