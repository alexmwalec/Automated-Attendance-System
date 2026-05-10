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


  late String _selectedSessionType;
  final List<String> _sessionTypes = ['Class', 'Lab', 'Exam'];

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
        // Fetching student from the global 'students' collection
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
            _showSnack('Captured: ${student['name']} ${student['surname']}', tealDark);
          }
        } else {
          _showSnack('Student $code not found', Colors.red);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AAS Attendance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.courseCode, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Displaying the specific course being scanned for
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: tealDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Session Type Selector (Class/Lab/Exam)
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
                        child: const Center(child: CircularProgressIndicator(color: tealPrimary)),
                      ),
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

            // Dynamic Session Count Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                tileColor: Colors.white,
                leading: const Icon(Icons.group, color: tealPrimary),
                title: Text("${_scannedStudents.length} Students Scanned", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Selected Course: ${widget.courseCode}"),
                trailing: Text(_selectedSessionType, style: const TextStyle(color: tealPrimary, fontWeight: FontWeight.bold)),
              ),
            )
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
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Confirm'),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
      ),
    );
  }
}