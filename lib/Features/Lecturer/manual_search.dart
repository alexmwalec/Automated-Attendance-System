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
      // Since 'courses' is a string and regNo is likely the Document ID,
      // we fetch students whose ID starts with the query.
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
            'regNo': doc.id, // The document ID is the Reg No
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
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Search ${widget.courseCode}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.all(16.0),
            color: tealPrimary,
            child: TextField(
              controller: _ctrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter Reg Number (e.g. bed-com-32-21)",
                prefixIcon: const Icon(Icons.search, color: tealPrimary),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); _onSearchChanged(''); })
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          if (_isLoading) const LinearProgressIndicator(color: tealDark),

          Expanded(
            child: _results.isEmpty && _ctrl.text.isNotEmpty && !_isLoading
                ? const Center(child: Text("No matching students found in this course."))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final s = _results[i];
                String reg = s['regNo']!;
                String name = s['name']!;
                String surname = s['surname']!;

                // Check if already in the scanned list
                bool alreadyAdded = widget.existingStudents.any(
                        (e) => e['regNo']?.toLowerCase() == reg.toLowerCase());

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tealLight,
                      child: Text(name[0], style: const TextStyle(color: tealDark, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(reg, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("$name $surname"),
                    trailing: alreadyAdded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.add_circle_outline, color: tealPrimary),
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