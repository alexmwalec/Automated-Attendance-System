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
      //  Get the course document to find enrolled students
      DocumentSnapshot courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseCode)
          .get();

      if (!courseDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      //  Extract the comma-separated string from the array [0]
      List<dynamic> enrolledArray = courseDoc.get('enrolledStudents') ?? [];
      if (enrolledArray.isEmpty) {
        setState(() { _results = []; _isLoading = false; });
        return;
      }

      String allRegStr = enrolledArray[0].toString();

      //  Split and filter the list by the user's input
      List<String> matches = allRegStr
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.contains(q))
          .toList();

      if (matches.isEmpty) {
        setState(() { _results = []; _isLoading = false; });
        return;
      }

      //  Fetch full student details for the matching registration numbers
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('regNo', whereIn: matches.take(30).toList())
          .get();

      final List<Map<String, String>> searchResults = studentSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'regNo': data['regNo']?.toString() ?? 'N/A',
          'name': data['name']?.toString() ?? 'Unknown',
          'surname': data['surname']?.toString() ?? '',
        };
      }).toList();

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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Search Students (${widget.courseCode})',
            style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _ctrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter Reg Number...",
                prefixIcon: const Icon(Icons.search, color: tealPrimary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(color: tealPrimary),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final s = _results[i];
                // SAFETY: Provide fallback if strings are null
                String reg = s['regNo'] ?? 'N/A';
                String name = s['name'] ?? 'Unknown';
                String surname = s['surname'] ?? '';

                bool added = widget.existingStudents.any((e) => e['regNo'] == reg);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tealPrimary,
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(reg, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$name $surname"),
                  trailing: Icon(added ? Icons.check_circle : Icons.add_circle_outline,
                      color: added ? tealPrimary : tealDark),
                  onTap: added ? null : () {
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