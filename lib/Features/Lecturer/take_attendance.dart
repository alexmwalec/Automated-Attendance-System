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
  State<InvigilatorTakeAttendance> createState() =>
      _InvigilatorTakeAttendanceState();
}

class _InvigilatorTakeAttendanceState extends State<InvigilatorTakeAttendance> {
  final MobileScannerController _cameraController = MobileScannerController();
  final List<Map<String, String>> _scannedStudents = [];
  int _currentIndex = 1;

  List<Map<String, dynamic>> _allEligibleStudents = [];
  bool _isLoadingStudents = true;

  String? _lastScanned;
  Timer? _scanCooldown;
  bool _isSubmitting = false;

  String? _currentUserName;

  // ── Mirrors AttendancePage: selectedSessionType driven by ChoiceChip ──
  late String _selectedSessionType;
  final List<String> _sessionTypes = ['Class', 'Lab', 'Exam'];

  @override
  void initState() {
    super.initState();
    _selectedSessionType = widget.sessionType;
    _fetchCurrentUserName();
    _loadCourseStudents();
  }

  // ── ALL LOGIC BELOW IS UNCHANGED ─────────────────────────────────────────

  Future<void> _fetchCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
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
      final snap =
          await FirebaseFirestore.instance.collection('students').get();
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
    _scanCooldown =
        Timer(const Duration(seconds: 2), () => _lastScanned = null);

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
      _showSnack(
          'Student $regNo not registered for ${widget.courseCode}', Colors.red);
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
        lecturerId =
            assignmentQuery.docs.first.data()['createdByUid'] ?? 'invigilator';
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
        'sessionType': _selectedSessionType,
        'venue': widget.venue,
        'date': widget.date,
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': lecturerId,
        'submittedBy': _currentUserName,
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

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: bg,
          duration: const Duration(seconds: 2)),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

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
            const Text(
              'AAS Attendance',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              widget.courseCode,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Course Info Banner ──────────────────────────────────────────
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recording for: ${widget.courseCode}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: tealDark),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              widget.venue,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Enrolled count badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: tealPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isLoadingStudents
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            '${_allEligibleStudents.length} Enrolled',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Session Type Selector ───────────────────────────────────────
            const Text(
              "Session Type",
              style: TextStyle(fontWeight: FontWeight.bold, color: tealDark),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _sessionTypes.map((type) {
                final bool isSelected = _selectedSessionType == type;
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

            // ── Scanner View ────────────────────────────────────────────────
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
                    MobileScanner(
                      controller: _cameraController,
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          if (barcode.rawValue != null) {
                            _handleScan(barcode.rawValue!);
                          }
                        }
                      },
                    ),
                    // Scanned counter overlay
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_scannedStudents.length} / ${_allEligibleStudents.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (_isLoadingStudents)
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
            const SizedBox(height: 16),

            // ── Manual Search Button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManualSearch(
                      existingStudents: _scannedStudents,
                      onStudentAdded: _onManualStudentAdded,
                      courseCode: widget.courseCode,
                    ),
                  ),
                ).then((_) => setState(() {})),
                icon: const Icon(Icons.person_search, color: tealPrimary),
                label: const Text('Add Student Manually',
                    style: TextStyle(color: tealPrimary)),
              ),
            ),
            const SizedBox(height: 16),

            // ── Summary Card ────────────────────────────────────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.group, color: tealPrimary),
                title: Text(
                  '${_scannedStudents.length} Students Scanned',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Course: ${widget.courseCode}'),
                trailing: Text(
                  _selectedSessionType,
                  style: const TextStyle(
                      color: tealPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Scanned Students List ───────────────────────────────────────
            if (_scannedStudents.isNotEmpty) ...[
              const Text(
                "SCANNED STUDENTS",
                style: TextStyle(
                    color: tealDark, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tealPrimary.withOpacity(0.2)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _scannedStudents.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) {
                    // Show newest first
                    final s = _scannedStudents[_scannedStudents.length - 1 - i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tealLight,
                        child: Text(
                          (s['name'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                              color: tealDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        s['regNo']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${s['name']} ${s['surname']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => setState(() => _scannedStudents
                            .removeWhere((st) => st['regNo'] == s['regNo'])),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Submit Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealPrimary,
                  disabledBackgroundColor: tealPrimary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _scannedStudents.isEmpty || _isSubmitting
                    ? null
                    : _submitToFirebase,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SUBMIT ATTENDANCE',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          if (index == 0) Navigator.pop(context);
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle), label: 'Confirm'),
        ],
      ),
    );
  }
}
