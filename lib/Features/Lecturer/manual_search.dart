import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class ManualSearch extends StatefulWidget {
  final List<Map<String, String>> existingStudents;
  final void Function(Map<String, String>) onStudentAdded;

  const ManualSearch({super.key, required this.existingStudents, required this.onStudentAdded});

  @override
  State<ManualSearch> createState() => _ManualSearchState();
}

class _ManualSearchState extends State<ManualSearch> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isLoading = false;

  void _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    // Firestore prefix search (Case-sensitive based on your data)
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('regNo', isGreaterThanOrEqualTo: q)
        .where('regNo', isLessThanOrEqualTo: '$q\uf8ff')
        .get();

    setState(() {
      _results = snapshot.docs.map((doc) => {
        'regNo': doc['regNo'].toString(),
        'name': doc['name'].toString(),
        'surname': doc['surname'].toString(),
      }).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(backgroundColor: tealPrimary, title: const Text('Manual Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _ctrl,
              onChanged: _search,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter Registration Number",
                prefixIcon: const Icon(Icons.search),
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
                bool added = widget.existingStudents.any((e) => e['regNo'] == s['regNo']);
                return ListTile(
                  title: Text(s['regNo']!),
                  subtitle: Text("${s['name']} ${s['surname']}"),
                  trailing: added ? const Icon(Icons.check_circle, color: tealPrimary) : const Icon(Icons.add_circle_outline),
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