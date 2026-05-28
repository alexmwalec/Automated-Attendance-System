import 'package:automated_attendance_system/Features/Lecturer/take_attendance.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(),
            const SizedBox(height: 24),
            const Text(
              'ACTIVE SESSIONS',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: tealDark),
            ),
            const SizedBox(height: 10),
            _buildCourseGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: tealPrimary.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
          'Select an active session to start recording attendance.',
          style: TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }

  Widget _buildCourseGrid() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('active_sessions')
          .where('lecturerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: tealPrimary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                "No active sessions found.\nCreate active sessions first.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.0,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final session = docs[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => _showChoiceDialog(session),
              child: Container(
                decoration: BoxDecoration(
                  color: tealPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tealPrimary),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      session['courseCode'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      session['sessionType'],
                      style: const TextStyle(fontSize: 12, color: tealDark),
                    ),
                    if (session['startTime'] != null)
                      Text(
                        "${session['startTime']} - ${session['endTime']}",
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChoiceDialog(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Session: ${session['courseCode']}"),
        content:
            const Text("Would you like to take attendance for this session?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendancePage(
                    courseCode: session['courseCode'],
                    sessionType: session['sessionType'],
                    room: session['room'] ?? 'TBA',
                  ),
                ),
              );
            },
            child: const Text("Take Attendance",
                style: TextStyle(color: tealPrimary)),
          ),
        ],
      ),
    );
  }
}
