import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const Color scanAccent = Color(0xFF2D9B8C);

  final MobileScannerController cameraController = MobileScannerController();
  final Set<String> _scannedStudentIds = {};

  bool _isProcessing = false;
  Timer? _noDetectionTimer;

  @override
  void initState() {
    super.initState();
    _resetTimeoutTimer();
  }

  void _resetTimeoutTimer() {
    _noDetectionTimer?.cancel();
    _noDetectionTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isProcessing) {
        debugPrint("4 seconds passed: No QR code found. Ready for next attempt.");
        cameraController.stop().then((_) => cameraController.start());
        _resetTimeoutTimer();
      }
    });
  }

  @override
  void dispose() {
    _noDetectionTimer?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        _isProcessing = true;
        _noDetectionTimer?.cancel();

        if (_scannedStudentIds.contains(code)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student $code already marked present!'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          setState(() {
            _scannedStudentIds.add(code);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance Captured: $code'),
              backgroundColor: tealDark,
              duration: const Duration(seconds: 1),
            ),
          );
        }

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _isProcessing = false);
            _resetTimeoutTimer();
          }
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        title: const Text('Live Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: tealPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScannedStudentsPage(scannedIds: _scannedStudentIds),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "Total: ${_scannedStudentIds.length}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tealPrimary, width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: _handleCapture,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Verified Attendance List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tealDark)),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _scannedStudentIds.isEmpty
                  ? const Center(child: Text("No scans yet. Start scanning IDs!"))
                  : ListView.builder(
                itemCount: _scannedStudentIds.length,
                itemBuilder: (context, index) {
                  String id = _scannedStudentIds.elementAt(_scannedStudentIds.length - 1 - index);
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text("Student ID: $id"),
                    subtitle: Text("Time: ${DateTime.now().hour}:${DateTime.now().minute}"),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class ScannedStudentsPage extends StatelessWidget {
  final Set<String> scannedIds;

  const ScannedStudentsPage({super.key, required this.scannedIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text("Attendance List", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: scannedIds.isEmpty
          ? const Center(
        child: Text(
          "No students scanned yet.",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: scannedIds.length,
        itemBuilder: (context, index) {
          String id = scannedIds.elementAt(index);
          return ListTile(
            leading: const Icon(Icons.person, color: tealPrimary),
            title: Text(
              "Student ID / Name: $id",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Status: Present",
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: const Icon(Icons.verified, color: Colors.green),
          );
        },
      ),
    );
  }
}