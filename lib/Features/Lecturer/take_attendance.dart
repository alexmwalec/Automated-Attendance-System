import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Firebase
import 'manual_search.dart';
import 'submit_list.dart';
import 'attendance_history.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  final List<Map<String, String>> _scannedStudents = [];
  bool _isProcessing = false;

  // New Fields for Firebase Structure
  String _selectedSessionType = 'Class';
  final List<String> _sessionTypes = ['Class', 'Lab', 'Exam'];
  final String _courseCode = "COM 411";

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
        var doc = await FirebaseFirestore.instance.collection('students').doc(code).get();

        if (doc.exists) {
          final data = doc.data()!;
          final student = {
            'regNo': data['regNo'].toString(),
            'name': data['name'].toString(),
            'surname': data['surname'].toString(),
          };

          final alreadyAdded = _scannedStudents.any((s) => s['regNo'] == student['regNo']);

          if (alreadyAdded) {
            _showSnack('${student['regNo']} already marked!', Colors.orange);
          } else {
            setState(() => _scannedStudents.add(student));
            _showSnack('Captured: ${student['name' 'surname']}', tealDark);
          }
        } else {
          _showSnack('Student $code not  found', Colors.red);
        }
      } catch (e) {
        _showSnack('Database Error: $e', Colors.red);
      }

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _isProcessing = false);
      break;
    }
  }

  void _showSnack(String msg, Color color) {
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
          onStudentAdded: (student) => setState(() => _scannedStudents.add(student)),
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
        title: const Text('AAS Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Type Selector
            const Text("Session Type", style: TextStyle(fontWeight: FontWeight.bold, color: tealDark)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _sessionTypes.map((type) {
                bool isSelected = _selectedSessionType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: tealPrimary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  onSelected: (val) { if(val) setState(() => _selectedSessionType = type); },
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
                      Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: tealPrimary))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goManual,
                icon: const Icon(Icons.person_search, color: tealPrimary),
                label: const Text('Add Student Manually', style: TextStyle(color: tealPrimary)),
              ),
            ),
            const SizedBox(height: 16),

            // Scanned Count Card
            Card(
              child: ListTile(
                title: Text("Course: $_courseCode"),
                subtitle: Text("Total Scanned: ${_scannedStudents.length}"),
                trailing: const Icon(Icons.people, color: tealPrimary),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pop(context);
          if (i == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SubmitList(
              students: _scannedStudents,
              sessionType: _selectedSessionType,
              courseCode: _courseCode,
            )));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Submit'),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
      ),
    );
  }
}