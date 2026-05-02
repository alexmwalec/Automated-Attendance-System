import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  int _failedAttempts = 0;

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null || code.isEmpty) continue;
      _isProcessing = true;

      // TODO: replace with your real DB lookup
      // Expects QR value formatted as "regNo|name|surname"
      final parts = code.split('|');
      if (parts.length < 3) {
        _failedAttempts++;
        _showSnack(
            'Student not found (attempt $_failedAttempts/3)', Colors.orange);
        if (_failedAttempts >= 3) {
          _failedAttempts = 0;
          Future.delayed(const Duration(milliseconds: 400), () => _goManual());
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isProcessing = false);
          });
        }
        break;
      }

      final student = {
        'regNo': parts[0],
        'name': parts[1],
        'surname': parts[2],
      };
      final alreadyAdded =
          _scannedStudents.any((s) => s['regNo'] == student['regNo']);

      if (alreadyAdded) {
        _showSnack(
            '${student['regNo']} already marked present!', Colors.orange);
      } else {
        setState(() => _scannedStudents.add(student));
        _showSnack('Captured: ${student['regNo']}', tealDark);
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
      break;
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goManual() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualSearch(
          existingStudents: _scannedStudents,
          onStudentAdded: (student) =>
              setState(() => _scannedStudents.add(student)),
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
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'AAS',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              backgroundColor: tealDark,
              radius: 15,
              child: Icon(Icons.person_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) {
            Navigator.pop(context);
          } else if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceHistory()),
            );
          } else if (i == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubmitList(students: _scannedStudents),
              ),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Attendance History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check),
            label: 'Submit List',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
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
                          child: CircularProgressIndicator(
                              color: tealPrimary, strokeWidth: 2),
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
                onPressed: _goManual,
                icon: const Icon(Icons.person_search,
                    color: tealPrimary, size: 16),
                label: const Text(
                  'Add Manually',
                  style: TextStyle(
                      color: tealPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: tealPrimary, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scanning Instructions',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tealPrimary),
                  ),
                  const SizedBox(height: 8),
                  _instruction('1 Point camera at student ID QR code'),
                  _instruction('2 Wait until student data has been fetched'),
                  _instruction('3 Hold steady until scanned'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instruction(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
        ),
      );
}
