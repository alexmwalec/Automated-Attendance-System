import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            appBar: _sharedAppBar(),
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

AppBar _sharedAppBar() => AppBar(
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

  // ── Total student count loaded once from Firestore ──────────────────────
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadTotalStudents();
  }

  Future<void> _loadTotalStudents() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('students').count().get();
      if (mounted) {
        setState(() => _totalStudents = snap.count ?? 0);
      }
    } catch (_) {
      // Fallback: fetch docs and count (for older SDK versions)
      try {
        final snap =
            await FirebaseFirestore.instance.collection('students').get();
        if (mounted) {
          setState(() => _totalStudents = snap.docs.length);
        }
      } catch (_) {}
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
      // ── Clean AppBar — no details strip attached ─────────────────────────
      appBar: _sharedAppBar(),

      body: Column(
        children: [
          // ── Details strip: separate bar below the AppBar ─────────────────
          Container(
            color: tealDark,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(Icons.school, widget.courseCode),
                  const SizedBox(width: 14),
                  _chip(Icons.category, widget.sessionType),
                  const SizedBox(width: 14),
                  _chip(Icons.location_on, widget.venue),
                  const SizedBox(width: 14),
                  _chip(Icons.calendar_today, widget.date),
                ],
              ),
            ),
          ),

          // ── Camera ───────────────────────────────────────────────────────
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
                  // ── "X / total scanned" badge ───────────────────────────
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
                        '${_scannedStudents.length} / $_totalStudents scanned',
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

          // ── Inline manual search bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _InvigilatorManualSearch(
                    existingStudents: _scannedStudents,
                    onStudentAdded: _onManualStudentAdded,
                  ),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB2DFDB)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: tealPrimary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Add student by searching reg number',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scanned list ─────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    color: tealLight,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('REG NO',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: tealDark))),
                        Expanded(
                            flex: 4,
                            child: Text('FULL NAME',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: tealDark))),
                        Expanded(
                            flex: 2,
                            child: Text('STATUS',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: tealDark))),
                        SizedBox(width: 32),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFB2DFDB)),
                  Expanded(
                    child: _scannedStudents.isEmpty
                        ? const Center(
                            child: Text(
                              'No students scanned yet.\nScan a QR or use the search bar above.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _scannedStudents.length,
                            itemBuilder: (context, i) {
                              final s = _scannedStudents[
                                  _scannedStudents.length - 1 - i];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
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
                                            style:
                                                const TextStyle(fontSize: 10))),
                                    Expanded(
                                        flex: 4,
                                        child: Text(
                                            '${s['name']} ${s['surname']}',
                                            style:
                                                const TextStyle(fontSize: 10))),
                                    const Expanded(
                                        flex: 2,
                                        child: Text('Present',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: tealDark,
                                                fontWeight: FontWeight.bold))),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 16, color: Colors.red),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() =>
                                            _scannedStudents.removeWhere((st) =>
                                                st['regNo'] == s['regNo']));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // ── Submit ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _scannedStudents.isEmpty || _isSubmitting
                            ? null
                            : _showConfirmDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tealPrimary,
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
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
                                    fontSize: 12)),
                      ),
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
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Manual Search (logic unchanged)
// ══════════════════════════════════════════════════════════════════════════════
class _InvigilatorManualSearch extends StatefulWidget {
  final List<Map<String, String>> existingStudents;
  final void Function(Map<String, String>) onStudentAdded;

  const _InvigilatorManualSearch({
    required this.existingStudents,
    required this.onStudentAdded,
  });

  @override
  State<_InvigilatorManualSearch> createState() =>
      _InvigilatorManualSearchState();
}

class _InvigilatorManualSearchState extends State<_InvigilatorManualSearch> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
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
          _results = combined.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Search error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('AAS',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search Reg No or Student Name',
                prefixIcon: const Icon(Icons.search, color: tealPrimary),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          _onSearchChanged('');
                        })
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: tealPrimary),
          Expanded(
            child: _results.isEmpty && _ctrl.text.isNotEmpty && !_isLoading
                ? const Center(child: Text('No students found.'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final s = _results[i];
                      final added = widget.existingStudents
                          .any((e) => e['regNo'] == s['regNo']);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tealPrimary,
                          child: Text(
                              s['name']!.isNotEmpty ? s['name']![0] : '?',
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(s['regNo']!,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s['name']} ${s['surname']}'),
                        trailing: added
                            ? const Icon(Icons.check_circle, color: tealPrimary)
                            : const Icon(Icons.add_circle_outline,
                                color: tealDark),
                        onTap: added
                            ? null
                            : () {
                                widget.onStudentAdded(s);
                                Navigator.pop(context);
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
