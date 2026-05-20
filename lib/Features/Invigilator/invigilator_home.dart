import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Lecturer/take_attendance.dart';

class InvigilatorHome extends StatelessWidget {
  const InvigilatorHome({super.key});
  static const Color primaryColor = Color(0xFF2E9E8E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Invigilator Dashboard', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exam_assignments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1, // +1 for the Header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildWelcomeCard();
              }

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
                        builder: (_) => AttendancePage(
                          courseCode: data['course'],
                          sessionType: data['sessionType'],
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
      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Tap on a task below to start taking attendance.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.assignment, color: Color(0xFF2E9E8E)),
              const SizedBox(width: 10),
              Text(course, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ]),
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _info('Venue', venue),
              _info('Date', date),
              _info('Time', time),
            ])
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String val) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ]);
  }
}