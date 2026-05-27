import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Invigilator_viewlist.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealLight = Color(0xFFDFF2EF);

class InvigilatorAttendanceList extends StatefulWidget {
  const InvigilatorAttendanceList({super.key});

  @override
  State<InvigilatorAttendanceList> createState() => _InvigilatorAttendanceListState();
}

class _InvigilatorAttendanceListState extends State<InvigilatorAttendanceList> {
  String? _userName;

  // Use a nullable variable for the picker, but initialize it to now
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Initialize date inside initState to ensure it's set before first build
    _selectedDate = DateTime.now();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && doc.exists) {
          setState(() {
            _userName = "${doc.data()?['name'] ?? ''} ${doc.data()?['surname'] ?? ''}".trim();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  // Helper with an explicit null check to prevent "reading year" error
  String _formatDate(DateTime? dt) {
    if (dt == null) return ""; // Guard against null

    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    // Ensure we have a non-null date to start the picker
    final DateTime initial = _selectedDate ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial, // Ensure initial isn't in future
      firstDate: DateTime(2000),
      lastDate: now, // RESTRICTS SELECTION TO CURRENT DATE AND PREVIOUS ONES
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: tealPrimary,
              onPrimary: Colors.white,
              onSurface: tealPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if user name or date is not yet ready
    if (_userName == null || _selectedDate == null) {
      return const Scaffold(
        backgroundColor: tealLight,
        body: Center(child: CircularProgressIndicator(color: tealPrimary)),
      );
    }

    final String dateFilter = _formatDate(_selectedDate);

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Submissions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Indicator Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: tealPrimary.withOpacity(0.1),
              border: const Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 16, color: tealPrimary),
                const SizedBox(width: 8),
                Text(
                  "Records for: ",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                Text(
                  dateFilter,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tealPrimary
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit, size: 14, color: tealPrimary),
                  label: const Text(
                    "Change",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tealPrimary),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Optimized query
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('submittedBy', isEqualTo: _userName)
                  .where('date', isEqualTo: dateFilter)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text("Error: ${snap.error}"));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: tealPrimary));
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: tealPrimary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          "No records found for $dateFilter",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tealLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history_edu, color: tealPrimary),
                        ),
                        title: Text(
                          "${data['courseCode'] ?? 'N/A'} - ${data['sessionType'] ?? 'N/A'}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${data['date']} • ${data['totalPresent'] ?? 0} Present",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ViewList(attendanceData: data)),
                        ),
                      ),
                    );
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