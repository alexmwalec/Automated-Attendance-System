import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class ManualSearch extends StatefulWidget {
  final List<Map<String, String>> existingStudents;
  final void Function(Map<String, String>) onStudentAdded;
  final String courseCode;

  const ManualSearch({
    super.key,
    required this.existingStudents,
    required this.onStudentAdded,
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

  void _performSearch(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: q)
          .where(FieldPath.documentId, isLessThanOrEqualTo: '$q\uf8ff')
          .limit(40)
          .get();

      final List<Map<String, String>> searchResults = [];

      for (var doc in studentSnapshot.docs) {
        final data = doc.data();
        final String coursesString = data['courses']?.toString() ?? '';

        final List<String> courseList = coursesString
            .split(',')
            .map((e) => e.trim().toUpperCase())
            .toList();

        if (courseList.contains(widget.courseCode.trim().toUpperCase())) {
          searchResults.add({
            'regNo': doc.id,
            'name': data['name']?.toString() ?? 'Unknown',
            'surname': data['surname']?.toString() ?? '',
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,

      // ── HEADER ── separated from body, no search inside it
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 2,
        shadowColor: tealDark.withOpacity(0.4),
        // ← back arrow kept
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AAS PORTAL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // ── BODY ── light teal background; search card floats on top
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Card (separated from header)
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
                  // Title inside the card
                  const Text(
                    'Search student',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search TextField
                  TextField(
                    controller: _ctrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      hintText: 'Search by registration number',
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

          // ── "All results" label
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              'All results',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tealDark.withOpacity(0.75),
                letterSpacing: 0.4,
              ),
            ),
          ),

          // ── Results list
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

                      final bool alreadyAdded = widget.existingStudents.any(
                          (e) =>
                              e['regNo']?.toLowerCase() == reg.toLowerCase());

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
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
                            backgroundColor: tealLight,
                            radius: 22,
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: tealDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            reg,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          subtitle: Text(
                            '$name $surname',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green, size: 22)
                              : const Icon(Icons.add_circle_outline,
                                  color: tealPrimary, size: 22),
                          onTap: alreadyAdded
                              ? null
                              : () {
                                  widget.onStudentAdded(s);
                                  Navigator.pop(context);
                                },
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
