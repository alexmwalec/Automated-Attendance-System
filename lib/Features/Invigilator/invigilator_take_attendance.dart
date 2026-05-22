import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final MobileScannerController _cameraController = MobileScannerController();
  final List<Map<String, String>> _scannedStudents = [];
  int _currentIndex = 1; // Default to Attendance tab

  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isLoadingStudents = true;

  String? _lastScanned;
  Timer? _scanCooldown;
  bool _isSubmitting = false;

  // 1. Define the variable
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName(); // 2. Fetch the name
    _loadCourseStudents();
  }

  // 3. Add the fetch method
  Future<void> _fetchCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            String firstName = data?['name'] ?? '';
            String lastName = data?['surname'] ?? '';
            _currentUserName = "$firstName $lastName".trim();
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
            'regNo': doc.id,
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
    _cameraController.dispose();
    _scanCooldown?.cancel();
    super.dispose();
  }

  Future<void> _handleScan(String rawValue) async {
    final regNo = rawValue.trim().toUpperCase();
    if (_lastScanned == regNo) return;
    _lastScanned = regNo;
    _scanCooldown?.cancel();
    _scanCooldown = Timer(const Duration(seconds: 2), () => _lastScanned = null);

    if (_scannedStudents.any((s) => s['regNo'] == regNo)) {
      HapticFeedback.mediumImpact();
      _showSnack('$regNo already marked present', Colors.orange);
      return;
    }

    final studentData = _allEligibleStudents.firstWhere(
          (s) => s['regNo'].toString().toUpperCase() == regNo,
      orElse: () => {},
    );

    if (studentData.isEmpty) {
      HapticFeedback.heavyImpact();
      _showSnack('Student $regNo not registered for ${widget.courseCode}', Colors.red);
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _scannedStudents.add({
        'regNo': regNo,
        'name': studentData['name']?.toString() ?? 'Unknown',
        'surname': studentData['surname']?.toString() ?? '',
      });
    });
    _showSnack('✓ ${studentData['name']} marked present', tealDark);
  }

  void _onManualStudentAdded(Map<String, String> student) {
    if (_scannedStudents.any((s) => s['regNo'] == student['regNo'])) {
      _showSnack('${student['regNo']} already marked present', Colors.orange);
      return;
    }
    setState(() => _scannedStudents.add(student));
  }

  Future<void> _submitToFirebase() async {
    // 4. Ensure we don't submit if name is missing
    if (_currentUserName == null) {
      _showSnack('User profile not loaded. Please wait.', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final assignmentQuery = await FirebaseFirestore.instance
          .collection('exam_assignments')
          .where('course', isEqualTo: widget.courseCode)
          .where('date', isEqualTo: widget.date)
          .limit(1)
          .get();

      String lecturerId = 'invigilator';
      if (assignmentQuery.docs.isNotEmpty) {
        lecturerId = assignmentQuery.docs.first.data()['createdByUid'] ?? 'invigilator';
      }

      final presentRegNos = _scannedStudents.map((s) => s['regNo']).toSet();
      List<Map<String, dynamic>> fullAttendanceList = [];

      for (var student in _allEligibleStudents) {
        final regNo = student['regNo'];
        fullAttendanceList.add({
          'regNo': regNo,
          'name': student['name'],
          'surname': student['surname'],
          'status': presentRegNos.contains(regNo) ? 'Present' : 'Absent',
        });
      }

      await FirebaseFirestore.instance.collection('attendance').add({
        'courseCode': widget.courseCode,
        'sessionType': widget.sessionType,
        'venue': widget.venue,
        'date': widget.date,
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': lecturerId,
        'submittedBy': _currentUserName, // Now defined!
        'fullAttendanceList': fullAttendanceList,
        'totalPresent': _scannedStudents.length,
        'totalEnrolled': _allEligibleStudents.length,
        'status': 'Submitted',
      });

      if (mounted) {
        _showSnack('Attendance submitted successfully!', Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('Error: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        title: const Text('Take Attendance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Details Strip ──
          Container(
            color: tealDark,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoChip(Icons.school, widget.courseCode),
                _infoChip(Icons.location_on, widget.venue),
                _infoChip(Icons.people, '${_allEligibleStudents.length} Total'),
              ],
            ),
          ),

          // ── Camera Scanner ──
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MobileScanner(
                      controller: _cameraController,
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          if (barcode.rawValue != null) _handleScan(barcode.rawValue!);
                        }
                      },
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text('${_scannedStudents.length} / ${_allEligibleStudents.length} Scanned',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_isLoadingStudents)
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                ],
              ),
            ),
          ),

          // ── Manual Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManualSearch(
                    existingStudents: _scannedStudents,
                    onStudentAdded: _onManualStudentAdded,
                    courseCode: widget.courseCode,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade100)
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: tealPrimary, size: 20),
                    SizedBox(width: 10),
                    Text('Search student manually...', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),

          // ── Scanned List ──
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _scannedStudents.isEmpty
                  ? const Center(child: Text("No students scanned yet", style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _scannedStudents.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = _scannedStudents[_scannedStudents.length - 1 - i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s['regNo']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${s['name']} ${s['surname']}', style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _scannedStudents.removeWhere((st) => st['regNo'] == s['regNo'])),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Submit Attendance Button (Inside Body Column) ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _scannedStudents.isEmpty || _isSubmitting ? null : _submitToFirebase,
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'SUBMIT ATTENDANCE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── RESTORED BOTTOM NAVIGATION BAR ──
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          if (index == 0) Navigator.pop(context); // Go back to Home
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            activeIcon: Icon(Icons.edit_document),
            label: 'Report',
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg, duration: const Duration(seconds: 2)),
    );
  }
}