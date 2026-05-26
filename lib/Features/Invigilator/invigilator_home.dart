import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
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
          String firstName = data?['name'] ?? '';
          String lastName = data?['surname'] ?? '';
          _currentUserName = "$firstName $lastName".trim();
        });
      }
    }
  }

  Stream<List<QueryDocumentSnapshot>> _getCombinedSessions(String uid) {
    var webStream = FirebaseFirestore.instance
        .collection('exam_assignments')
        .where('invigilatorId', isEqualTo: uid)
        .snapshots();

    var mobileStream = FirebaseFirestore.instance
        .collection('active_sessions')
        .where('invigilatorId', isEqualTo: uid)
        .snapshots();

    return CombineLatestStream.list([webStream, mobileStream]).map((snapshots) {
      List<QueryDocumentSnapshot> combined = [];
      for (var snap in snapshots) {
        combined.addAll(snap.docs);
      }

      combined.sort((a, b) {
        DateTime dt1 = _parseDateTime((a.data() as Map)['createdAt']);
        DateTime dt2 = _parseDateTime((b.data() as Map)['createdAt']);
        return dt2.compareTo(dt1); // Descending order
      });

      return combined;
    });
  }

  // Helper method to handle mixed data types for dates
  DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime(2000);
    }
    return DateTime(2000);
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (_currentUserName == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Invigilator Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _getCombinedSessions(currentUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));

          final docs = snapshot.data!;

          if (docs.isEmpty) {
            return Column(
              children: [
                _buildWelcomeCard(),
                const Expanded(child: Center(child: Text("No assignments found.", style: TextStyle(color: Colors.grey, fontSize: 16)))),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildWelcomeCard();

              final data = docs[index - 1].data() as Map<String, dynamic>;
              final course = data['courseCode'] ?? data['course'] ?? 'Unknown';
              final venue = data['room'] ?? data['venue'] ?? 'N/A';
              final date = data['date'] ?? 'N/A';

              final String timeDisplay;
              if (data.containsKey('time')) {
                timeDisplay = data['time'];
              } else if (data.containsKey('startTime')) {
                timeDisplay = "${data['startTime']} - ${data['endTime']}";
              } else {
                timeDisplay = "N/A";
              }

              final isExam = data['sessionType'] == 'Exam';
              final sessionType = data['sessionType'] ?? (isExam ? 'Exam' : 'Class');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AssignmentCard(
                  course: course,
                  venue: venue,
                  date: date,
                  time: timeDisplay,
                  sessionType: sessionType,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvigilatorTakeAttendance(
                          courseCode: course,
                          sessionType: sessionType,
                          venue: venue,
                          date: date,
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
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, $_currentUserName!', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Below are your assigned sessions.', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final String course, venue, date, time, sessionType;
  final VoidCallback onTap;

  const _AssignmentCard({required this.course, required this.venue, required this.date, required this.time, required this.sessionType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
        child: Column(
          children: [
            Row(
              children: [
                Icon(sessionType == 'Exam' ? Icons.assignment_late : Icons.class_outlined),
                const SizedBox(width: 10),
                Text(course, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _info('Venue', venue),
                _info('Date', date),
                _info('Type', sessionType),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}