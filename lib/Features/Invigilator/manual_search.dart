import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_state.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class ManualSearch extends StatefulWidget {
  final String courseCode;

  const ManualSearch({
    super.key,
    required this.courseCode,
  });

  @override
  State<ManualSearch> createState() => _ManualSearchState();
}

class _ManualSearchState extends State<ManualSearch> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    AttendanceState.markedStudents.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AttendanceState.markedStudents.removeListener(_onStateChanged);
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

  void _performSearch(String query) async {
    final raw = query.trim().toLowerCase();
    // Normalize: accept both bed/com/27/22 and bed-com-27-22
    final q = raw.replaceAll('/', '-');

    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<Map<String, String>> searchResults = [];

      // Search by document ID (normalized hyphen format)
      final regSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: q)
          .where(FieldPath.documentId, isLessThanOrEqualTo: '$q\uf8ff')
          .limit(40)
          .get();

      for (var doc in regSnapshot.docs) {
        final data = doc.data();
        final String coursesString = data['courses']?.toString() ?? '';
        final List<String> courseList = coursesString
            .split(',')
            .map((e) => e.trim().toUpperCase())
            .toList();

        if (courseList.contains(widget.courseCode.trim().toUpperCase())) {
          final String docId = normalizeReg(doc.id);
          if (!searchResults.any((r) => r['regNo'] == docId)) {
            searchResults.add({
              'regNo': docId,
              'name': data['name']?.toString() ?? 'Unknown',
              'surname': data['surname']?.toString() ?? '',
            });
          }
        }
      }

      // Also search by name if query has no digits
      if (!q.contains(RegExp(r'[0-9]'))) {
        final nameSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('name', isGreaterThanOrEqualTo: raw)
            .where('name', isLessThanOrEqualTo: '$raw\uf8ff')
            .limit(20)
            .get();

        for (var doc in nameSnapshot.docs) {
          final data = doc.data();
          final String coursesString = data['courses']?.toString() ?? '';
          final List<String> courseList = coursesString
              .split(',')
              .map((e) => e.trim().toUpperCase())
              .toList();

          if (courseList.contains(widget.courseCode.trim().toUpperCase())) {
            final String docId = normalizeReg(doc.id);
            if (!searchResults.any((r) => r['regNo'] == docId)) {
              searchResults.add({
                'regNo': docId,
                'name': data['name']?.toString() ?? 'Unknown',
                'surname': data['surname']?.toString() ?? '',
              });
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _results = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isAlreadyMarked(String regNo) => AttendanceState.isMarked(regNo);

  void _addStudent(Map<String, String> student) {
    if (!_isAlreadyMarked(student['regNo']!)) {
      AttendanceState.addStudent(student);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added: ${student['name']} ${student['surname']}'),
          backgroundColor: tealPrimary,
          duration: const Duration(seconds: 1),
        ),
      );
      _ctrl.clear();
      _onSearchChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int markedCount = AttendanceState.markedStudents.value.length;

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 2,
        shadowColor: tealDark.withOpacity(0.4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search ${widget.courseCode}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: tealDark.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search student',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      hintText:
                          'Reg number (bed-com-32-21 or bed/com/32/21) or name',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(Icons.search,
                          color: tealPrimary, size: 20),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _ctrl.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: tealPrimary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(
                color: tealPrimary,
                backgroundColor: tealLight,
                minHeight: 2,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All results',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tealDark.withOpacity(0.75),
                    letterSpacing: 0.4,
                  ),
                ),
                if (markedCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tealPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$markedCount marked',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: tealPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty && _ctrl.text.isNotEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'No matching students found in this course.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final s = _results[i];
                      final String reg = s['regNo']!;
                      final String name = s['name']!;
                      final String surname = s['surname']!;
                      final bool alreadyMarked = _isAlreadyMarked(reg);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: alreadyMarked
                              ? Colors.green.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: alreadyMarked
                              ? Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: tealDark.withOpacity(0.07),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor:
                                alreadyMarked ? Colors.green : tealLight,
                            radius: 22,
                            child: Icon(
                              alreadyMarked ? Icons.check : Icons.person,
                              color: alreadyMarked ? Colors.white : tealDark,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            reg,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: alreadyMarked
                                  ? Colors.green
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          subtitle: Text(
                            '$name $surname',
                            style: TextStyle(
                              fontSize: 12,
                              color: alreadyMarked
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                          trailing: alreadyMarked
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Marked',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline,
                                  color: tealPrimary, size: 22),
                          onTap: alreadyMarked ? null : () => _addStudent(s),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
