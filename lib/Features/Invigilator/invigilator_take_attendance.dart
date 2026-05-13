import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Shared colours (match the rest of the app) ────────────────────────────
const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

// ══════════════════════════════════════════════════════════════════════════════
// Entry point
// ══════════════════════════════════════════════════════════════════════════════
class InvigilatorTakeAttendance extends StatelessWidget {
  const InvigilatorTakeAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exam_assignments')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: tealLight,
            body: Center(child: CircularProgressIndicator(color: tealPrimary)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            backgroundColor: tealLight,
            appBar: _buildAppBar(),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No exam assignment found.\nPlease wait for a lecturer to assign you an exam.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: tealDark),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final String courseCode = data['course'] ?? 'N/A';
        const String sessionType = 'Exam';
        final String venue = data['room'] ?? 'N/A';
        final String date = data['date'] ?? 'N/A';

        return _ScannerScreen(
          courseCode: courseCode,
          sessionType: sessionType,
          venue: venue,
          date: date,
        );
      },
    );
  }
}

// ── Shared AppBar builder ───────────────────────────────────────────
AppBar _buildAppBar() {
  return AppBar(
    backgroundColor: tealPrimary,
    automaticallyImplyLeading: false,
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
        padding: EdgeInsets.only(right: 16),
        child: CircleAvatar(
          backgroundColor: Colors.white24,
          radius: 15,
          child: Icon(Icons.person, color: Colors.white, size: 18),
        ),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Main scanner screen
// ══════════════════════════════════════════════════════════════════════════════
class _ScannerScreen extends StatefulWidget {
  final String courseCode;
  final String sessionType;
  final String venue;
  final String date;

  const _ScannerScreen({
    required this.courseCode,
    required this.sessionType,
    required this.venue,
    required this.date,
  });

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();

  final List<Map<String, String>> _scannedStudents = [];

  String? _lastScanned;
  Timer? _scanCooldown;

  bool _isSubmitting = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _cameraController.dispose();
    _scanCooldown?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String rawValue) async {
    final regNo = rawValue.trim().toUpperCase();

    if (_lastScanned == regNo) return;
    _lastScanned = regNo;
    _scanCooldown?.cancel();
    _scanCooldown = Timer(const Duration(seconds: 2), () {
      _lastScanned = null;
    });

    if (_scannedStudents.any((s) => s['regNo'] == regNo)) {
      HapticFeedback.mediumImpact();
      _showSnack('$regNo already marked present', Colors.orange);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('students')
          .where('regNo', isEqualTo: regNo)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        HapticFeedback.heavyImpact();
        _showSnack('Student $regNo not found in database', Colors.red);
        return;
      }

      final doc = query.docs.first.data();
      final student = {
        'regNo': doc['regNo']?.toString() ?? regNo,
        'name': doc['name']?.toString() ?? 'Unknown',
        'surname': doc['surname']?.toString() ?? '',
      };

      HapticFeedback.heavyImpact();
      setState(() => _scannedStudents.add(student));
      _showSnack('✓ ${student['name']} ${student['surname']} marked present',
          tealDark);
    } catch (e) {
      _showSnack('Error looking up student: $e', Colors.red);
    }
  }

  void _onManualStudentAdded(Map<String, String> student) {
    if (_scannedStudents.any((s) => s['regNo'] == student['regNo'])) {
      _showSnack('${student['regNo']} already marked present', Colors.orange);
      return;
    }
    setState(() => _scannedStudents.add(student));
    _showSnack(
        '✓ ${student['name']} ${student['surname']} added manually', tealDark);
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final upperQuery = q.toUpperCase();
      final nameQuery = q.length > 1
          ? q[0].toUpperCase() + q.substring(1).toLowerCase()
          : q.toUpperCase();

      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('students')
            .where('regNo', isGreaterThanOrEqualTo: upperQuery)
            .where('regNo', isLessThanOrEqualTo: '$upperQuery\uf8ff')
            .limit(10)
            .get(),
        FirebaseFirestore.instance
            .collection('students')
            .where('name', isGreaterThanOrEqualTo: nameQuery)
            .where('name', isLessThanOrEqualTo: '$nameQuery\uf8ff')
            .limit(10)
            .get(),
      ]);

      final Map<String, Map<String, String>> combined = {};
      for (var doc in results[0].docs) {
        combined[doc.id] = {
          'regNo': doc['regNo']?.toString() ?? '',
          'name': doc['name']?.toString() ?? '',
          'surname': doc['surname']?.toString() ?? '',
        };
      }
      for (var doc in results[1].docs) {
        combined[doc.id] = {
          'regNo': doc['regNo']?.toString() ?? '',
          'name': doc['name']?.toString() ?? '',
          'surname': doc['surname']?.toString() ?? '',
        };
      }

      if (mounted) {
        setState(() {
          _searchResults = combined.values.toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        _showSnack('Search error: $e', Colors.red);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _submitToFirebase() async {
    setState(() => _isSubmitting = true);
    try {
      final studentQuery =
          await FirebaseFirestore.instance.collection('students').get();
      final presentRegNos = _scannedStudents.map((s) => s['regNo']).toSet();

      List<Map<String, dynamic>> fullAttendanceList = [];

      for (var doc in studentQuery.docs) {
        final data = doc.data();
        final String regNo = data['regNo']?.toString() ?? '';
        final String name = data['name']?.toString() ?? 'Unknown';
        final String surname = data['surname']?.toString() ?? '';
        final String studentStatus = data['status']?.toString() ?? 'Active';

        if (presentRegNos.contains(regNo)) {
          fullAttendanceList.add({
            'regNo': regNo,
            'name': name,
            'surname': surname,
            'status': 'Present',
          });
        } else if (studentStatus == 'Exit') {
          fullAttendanceList.add({
            'regNo': regNo,
            'name': name,
            'surname': surname,
            'status': 'Exit',
          });
        } else {
          fullAttendanceList.add({
            'regNo': regNo,
            'name': name,
            'surname': surname,
            'status': 'Absent',
          });
        }
      }

      final attendanceRecord = {
        'courseCode': widget.courseCode,
        'sessionType': widget.sessionType,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': 'invigilator',
        'fullAttendanceList': fullAttendanceList,
        'totalPresent': _scannedStudents.length,
      };

      await FirebaseFirestore.instance
          .collection('attendance')
          .add(attendanceRecord);

      if (mounted) {
        _showSnack('Attendance submitted successfully!', Colors.green);
        setState(() {
          _scannedStudents.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('Error: $e', Colors.red);
      }
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Confirm Attendance',
            style: TextStyle(
                color: tealPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text(
            'Submit ${widget.sessionType} attendance for ${widget.courseCode}?\n\n'
            '${_scannedStudents.length} student(s) scanned. '
            'Missing students will be marked Absent or Exit automatically.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tealPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
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

  void _showSnack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: bg,
          duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Assignment details strip ──────────────────────────────────
          Container(
            color: tealDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(Icons.school, widget.courseCode),
                  const SizedBox(width: 16),
                  _chip(Icons.category, widget.sessionType),
                  const SizedBox(width: 16),
                  _chip(Icons.location_on, widget.venue),
                  const SizedBox(width: 16),
                  _chip(Icons.calendar_today, widget.date),
                ],
              ),
            ),
          ),

          // ── Camera Section ────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              color: tealLight,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: MobileScanner(
                      controller: _cameraController,
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          if (barcode.rawValue != null) {
                            _handleScan(barcode.rawValue!);
                          }
                        }
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tealDark.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_scannedStudents.length} scanned',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search Section with "Add student by searching reg number" ──
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Add student by searching reg number',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: tealDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by Registration Number or Name',
                      hintStyle:
                          const TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search,
                          color: tealPrimary, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: tealLight.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(color: tealPrimary),
                  ),
                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, i) {
                        final s = _searchResults[i];
                        final alreadyAdded = _scannedStudents
                            .any((e) => e['regNo'] == s['regNo']);
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: tealPrimary,
                            child: Text(
                              s['name']!.isNotEmpty ? s['name']![0] : '?',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text(
                            s['regNo']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            '${s['name']} ${s['surname']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check_circle,
                                  color: tealPrimary, size: 20)
                              : const Icon(Icons.add_circle_outline,
                                  color: tealDark, size: 20),
                          onTap: alreadyAdded
                              ? null
                              : () {
                                  _onManualStudentAdded(s);
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                        );
                      },
                    ),
                  ),
                const Divider(height: 1, color: Color(0xFFB2DFDB)),
              ],
            ),
          ),

          // ── Scanned Students List with Table Headers ─────────────────
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Table Header - Matching design
                  Container(
                    color: tealLight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('REG NO',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: tealDark,
                                    letterSpacing: 0.5))),
                        Expanded(
                            flex: 4,
                            child: Text('FULL NAME',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: tealDark,
                                    letterSpacing: 0.5))),
                        Expanded(
                            flex: 2,
                            child: Text('STATUS',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: tealDark,
                                    letterSpacing: 0.5))),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFB2DFDB)),
                  Expanded(
                    child: _scannedStudents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'No students scanned yet',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Scan a QR code or search above',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _scannedStudents.length,
                            itemBuilder: (context, i) {
                              final s = _scannedStudents[
                                  _scannedStudents.length - 1 - i];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFFE0F2F0), width: 0.8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                        flex: 3,
                                        child: Text(s['regNo'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500))),
                                    Expanded(
                                        flex: 4,
                                        child: Text(
                                            '${s['name']} ${s['surname']}',
                                            style:
                                                const TextStyle(fontSize: 12))),
                                    const Expanded(
                                        flex: 2,
                                        child: Text('Present',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: tealPrimary,
                                                fontWeight: FontWeight.bold))),
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            size: 18, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          setState(() => _scannedStudents
                                              .removeWhere((st) =>
                                                  st['regNo'] == s['regNo']));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // ── Submit button ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_scannedStudents.length} student(s) marked present',
                          style: TextStyle(
                            fontSize: 12,
                            color: tealDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _scannedStudents.isEmpty || _isSubmitting
                              ? null
                              : _showConfirmDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tealPrimary,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Submit Attendance',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
