import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManualSearch extends StatefulWidget {
  final List<Map<String, String>> existingStudents;
  final void Function(Map<String, String>) onStudentAdded;
  final String courseCode;

  const ManualSearch({super.key, required this.existingStudents, required this.onStudentAdded, required this.courseCode});

  @override
  State<ManualSearch> createState() => _ManualSearchState();
}

class _ManualSearchState extends State<ManualSearch> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(query));
  }

  void _performSearch(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _isLoading = true);

    try {
      final courseDoc = await FirebaseFirestore.instance.collection('courses').doc(widget.courseCode).get();
      if (!courseDoc.exists) { setState(() => _isLoading = false); return; }

      List<dynamic> enrolled = courseDoc.get('enrolledStudents') ?? [];
      if (enrolled.isEmpty) { setState(() => _isLoading = false); return; }

      // Split the comma string at index 0 and filter
      List<String> matches = enrolled[0].toString().split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.contains(q)).toList();

      if (matches.isEmpty) { setState(() { _results = []; _isLoading = false; }); return; }

      final studentSnap = await FirebaseFirestore.instance.collection('students')
          .where('regNo', whereIn: matches.take(30).toList()).get();

      setState(() {
        _results = studentSnap.docs.map((doc) => {
          'regNo': doc['regNo']?.toString() ?? 'N/A',
          'name': doc['name']?.toString() ?? 'Unknown',
          'surname': doc['surname']?.toString() ?? '',
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search ${widget.courseCode}')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(controller: _ctrl, onChanged: _onSearchChanged, decoration: const InputDecoration(hintText: 'Enter Reg Number', prefixIcon: Icon(Icons.search))),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, i) {
              final s = _results[i];
              bool added = widget.existingStudents.any((e) => e['regNo'] == s['regNo']);
              return ListTile(
                title: Text(s['regNo']!),
                subtitle: Text("${s['name']} ${s['surname']}"),
                trailing: Icon(added ? Icons.check_circle : Icons.add_circle_outline, color: added ? Colors.teal : Colors.grey),
                onTap: added ? null : () { widget.onStudentAdded(s); Navigator.pop(context); },
              );
            },
          ),
        ),
      ]),
    );
  }
}