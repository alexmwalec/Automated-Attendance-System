import 'dart:async'; // Required for Timer (Debouncing)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class ManualSearch extends StatefulWidget {
  final List<Map<String, String>> existingStudents;
  final void Function(Map<String, String>) onStudentAdded;

  const ManualSearch(
      {super.key,
      required this.existingStudents,
      required this.onStudentAdded});

  @override
  State<ManualSearch> createState() => _ManualSearchState();
}

class _ManualSearchState extends State<ManualSearch> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isLoading = false;

  // Debouncing Timer
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Debounced Search Function
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String upperQuery = q.toUpperCase();
      String nameQuery = q.length > 1
          ? q[0].toUpperCase() + q.substring(1).toLowerCase()
          : q.toUpperCase();

      final results = await Future.wait([
        // Search by Registration Number
        FirebaseFirestore.instance
            .collection('students')
            .where('regNo', isGreaterThanOrEqualTo: upperQuery)
            .where('regNo', isLessThanOrEqualTo: '$upperQuery\uf8ff')
            .limit(10)
            .get(),

        // Search by Name
        FirebaseFirestore.instance
            .collection('students')
            .where('name', isGreaterThanOrEqualTo: nameQuery)
            .where('name', isLessThanOrEqualTo: '$nameQuery\uf8ff')
            .limit(10)
            .get(),
      ]);

      final regSnapshot = results[0];
      final nameSnapshot = results[1];

      // 3. Combine results using a Map to prevent duplicates
      final Map<String, Map<String, String>> combined = {};

      for (var doc in regSnapshot.docs) {
        combined[doc.id] = {
          'regNo': doc['regNo']?.toString() ?? '',
          'name': doc['name']?.toString() ?? '',
          'surname': doc['surname']?.toString() ?? '',
        };
      }

      for (var doc in nameSnapshot.docs) {
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
              content: Text("Search error: $e"), backgroundColor: Colors.red),
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
        title:
            const Text('Manual Search', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _ctrl,
              onChanged: _onSearchChanged, // Calls the debouncer
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Search Reg No or Student Name",
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
                ? const Center(child: Text("No students found."))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final s = _results[i];
                      bool added = widget.existingStudents
                          .any((e) => e['regNo'] == s['regNo']);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tealPrimary,
                          child: Text(s['name']![0],
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(s['regNo']!,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${s['name']} ${s['surname']}"),
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
