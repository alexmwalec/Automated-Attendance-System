import 'package:flutter/material.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

// TODO: replace with your real DB/API call
// Dummy student database
const List<Map<String, String>> _kDatabase = [
  {'regNo': 'Bed-com-27-22', 'name': 'Sulphuric', 'surname': 'Moyo'},
  {'regNo': 'Bed-com-27-21', 'name': 'Sulphuric', 'surname': 'Moyo'},
  {'regNo': 'Bed-com-27-23', 'name': 'Sulphuric', 'surname': 'Moyo'},
  {'regNo': 'Bed-com-27-20', 'name': 'Sulphuric', 'surname': 'Moyo'},
  {'regNo': 'Bed-com-27-19', 'name': 'Sulphuric', 'surname': 'Moyo'},
  {'regNo': 'Bed-com-27-24', 'name': 'Sulphuric', 'surname': 'Moyo'},
  {'regNo': 'Bed-com-27-25', 'name': 'Sulphuric', 'surname': 'Moyo'},
];

enum _Method { all, regNo, email }

class ManualSearch extends StatefulWidget {
  final List<Map<String, String>> existingStudents;
  final void Function(Map<String, String>) onStudentAdded;

  const ManualSearch({
    super.key,
    required this.existingStudents,
    required this.onStudentAdded,
  });

  @override
  State<ManualSearch> createState() => _ManualSearchState();
}

class _ManualSearchState extends State<ManualSearch> {
  _Method _method = _Method.all;
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, String>> _results = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _results = _kDatabase.where((s) {
        switch (_method) {
          case _Method.regNo:
            return s['regNo']!.toLowerCase().contains(q);
          case _Method.email:
            return s['name']!.toLowerCase().contains(q) ||
                s['surname']!.toLowerCase().contains(q);
          case _Method.all:
            return s['regNo']!.toLowerCase().contains(q) ||
                s['name']!.toLowerCase().contains(q) ||
                s['surname']!.toLowerCase().contains(q);
        }
      }).toList();
    });
  }

  bool _alreadyAdded(Map<String, String> s) =>
      widget.existingStudents.any((e) => e['regNo'] == s['regNo']);

  void _add(Map<String, String> student) {
    if (_alreadyAdded(student)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student['regNo']} already in the list.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    widget.onStudentAdded(Map<String, String>.from(student));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${student['regNo']} added as Present.'),
        backgroundColor: tealDark,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
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
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              backgroundColor: tealDark,
              radius: 15,
              child: Icon(Icons.person_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search card
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: tealPrimary.withOpacity(0.2), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Search student',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                const Text('Search by',
                    style: TextStyle(fontSize: 11, color: Colors.black54)),
                const SizedBox(height: 8),
                // Method toggle pills
                Row(
                  children: [
                    _pill('All methods', _Method.all),
                    const SizedBox(width: 6),
                    _pill('Registration number', _Method.regNo),
                    const SizedBox(width: 6),
                    _pill('Email', _Method.email),
                  ],
                ),
                const SizedBox(height: 10),
                // Search field
                TextField(
                  controller: _ctrl,
                  onChanged: _search,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: Colors.black38),
                    hintText: _method == _Method.email
                        ? 'Search by email'
                        : 'Search by registration number',
                    hintStyle:
                        const TextStyle(fontSize: 11, color: Colors.black38),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                          color: Color(0xFFCCCCCC), width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                          color: Color(0xFFCCCCCC), width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          const BorderSide(color: tealPrimary, width: 1.2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                  ),
                ),
              ],
            ),
          ),

          // Results list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final s = _results[i];
                final added = _alreadyAdded(s);
                return GestureDetector(
                  onTap: () => _add(s),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFB2DFDB), width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s['regNo']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.2,
                              color: added ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                        if (added)
                          const Icon(Icons.check_circle,
                              color: tealPrimary, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, _Method method) {
    final selected = _method == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _method = method;
          _search(_ctrl.text);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? tealPrimary : Colors.transparent,
          border: Border.all(
            color: selected ? tealPrimary : Colors.grey.shade400,
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}
