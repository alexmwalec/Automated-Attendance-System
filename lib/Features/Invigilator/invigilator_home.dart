import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invigilator_take_attendance.dart';

class InvigilatorHome extends StatefulWidget {
  const InvigilatorHome({super.key});

  @override
  State<InvigilatorHome> createState() => _InvigilatorHomeState();
}

class _InvigilatorHomeState extends State<InvigilatorHome> {
  static const Color primaryColor = Color(0xFF2E9E8E);
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
  }

  Future<void> _fetchCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          // Using 'name' and 'surname' to match your Firestore schema
          String firstName = data?['name'] ?? '';
          String lastName = data?['surname'] ?? '';
          _currentUserName = "$firstName $lastName".trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's UID directly for the query
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (_currentUserName == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exam_assignments')
        // Query by the unique ID assigned from the Web dashboard
            .where('invigilatorId', isEqualTo: currentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Column(
              children: [
                _buildWelcomeCard(),
                const Expanded(
                  child: Center(
                    child: Text(
                      "No tasks assigned to you.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildWelcomeCard();

              final data = docs[index - 1].data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AssignmentCard(
                  course: data['course'] ?? 'N/A',
                  venue: data['room'] ?? 'N/A',
                  date: data['date'] ?? 'N/A',
                  time: data['time'] ?? 'N/A',
                  sessionType: data['sessionType'] ?? 'Exam',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvigilatorTakeAttendance(
                          courseCode: data['course'] ?? 'N/A',
                          sessionType: data['sessionType'] ?? 'N/A',
                          venue: data['room'] ?? 'N/A',
                          date: data['date'] ?? 'N/A',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $_currentUserName!',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Below are the sessions you are assigned to.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Assignment Card UI Component ──────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final String course, venue, date, time, sessionType;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.course,
    required this.venue,
    required this.date,
    required this.time,
    required this.sessionType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: Color(0xFF2E9E8E)),
                const SizedBox(width: 10),
                Text(
                  course,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _info('Venue', venue),
                _info('Date', date),
                _info('Time', time),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}