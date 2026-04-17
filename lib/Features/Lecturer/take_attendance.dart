import 'dart:async';
import 'package:flutter/foundation.dart';
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

  // Controller to manage the camera
  final MobileScannerController cameraController = MobileScannerController();

  // Storage for unique IDs (Sets automatically prevent duplicates)
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
    _noDetectionTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isProcessing) {
        debugPrint("3 seconds passed: No QR code found. Ready for next attempt.");
        // We stay "ready" or can pulse the UI to show it's still looking
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
    if (_isProcessing) return; // Ignore scans while we are "processing" a previous result

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        _isProcessing = true; // Lock scanning
        _noDetectionTimer?.cancel(); // Stop the 3s timeout

        // Check for Duplicates
        if (_scannedStudentIds.contains(code)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student $code already marked present!'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          // Add to list immediately (Visible  integrated list)
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

        // Wait 2 seconds before allowing the next scan (prevents rapid-fire scanning)
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text("Total: ${_scannedStudentIds.length}", style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. SCANNER SECTION
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

          // 2. ATTENDANCE LIST SECTION ("Another Page" content integrated here)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Verified Attendance List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tealDark)),
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