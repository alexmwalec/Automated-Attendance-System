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

      DocumentSnapshot courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseCode)
          .get();

      if (!courseDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      // Get the enrolledStudents array
      List<dynamic> enrolledArray = courseDoc.get('enrolledStudents') ?? [];
      if (enrolledArray.isEmpty) {
        setState(() { _results = []; _isLoading = false; });
        return;
      }

      String allRegNumbersString = enrolledArray[0].toString();

      //  Split by comma and filter locally by what the user typed
      List<String> filteredRegNumbers = allRegNumbersString
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.contains(q))
          .toList();

      if (filteredRegNumbers.isEmpty) {
        setState(() { _results = []; _isLoading = false; });
        return;
      }

      //  Fetch the student details for these specific Reg Number
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('regNo', whereIn: filteredRegNumbers.take(30).toList())
          .get();

      final List<Map<String, String>> searchResults = studentSnapshot.docs.map((doc) {
        return {
          'regNo': doc['regNo']?.toString() ?? '',
          'name': doc['name']?.toString() ?? '',
          'surname': doc['surname']?.toString() ?? '',
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
        title: Text('Search in ${widget.courseCode}',
            style: const TextStyle(color: Colors.white)),
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
                hintText: "Enter Reg Number (e.g. bsc-com...)",
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
                bool alreadyAdded = widget.existingStudents
                    .any((e) => e['regNo'] == s['regNo']);

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: tealPrimary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(s['regNo']!,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${s['name']} ${s['surname']}"),
                  trailing: Icon(
                    alreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                    color: alreadyAdded ? tealPrimary : tealDark,
                  ),
                  onTap: alreadyAdded ? null : () {
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