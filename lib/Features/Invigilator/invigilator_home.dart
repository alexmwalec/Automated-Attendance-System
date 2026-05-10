import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvigilatorHome extends StatelessWidget {
  const InvigilatorHome({super.key});

  static const Color tealPrimary = Color(0xFF2E9E8E);
  static const Color tealDark = Color(0xFF227A6D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: tealPrimary,
        title: const Text(
          'AAS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 15,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exam_assignments')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: tealPrimary));
          }

          String venue = 'No Venue Assigned';
          String date = 'No Date Set';
          String course = 'N/A';
          String time = 'N/A';

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final data =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            venue = data['room'] ?? 'No Venue Assigned';
            date = data['date'] ?? 'No Date Set';
            course = data['course'] ?? 'N/A';
            time = data['time'] ?? 'N/A';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [tealPrimary, tealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: tealPrimary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Use this dashboard to manage exam attendance.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Assigned Exam Details ─────────────────────────────────
                const Text(
                  'ASSIGNED EXAM DETAILS',
                  style: TextStyle(
                    color: tealDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Assigned Course — same card format as venue/date/time
                _buildInfoCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Assigned Course',
                  value: course,
                  color: tealPrimary,
                ),
                _buildInfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'Exam Venue',
                  value: venue,
                  color: Colors.blue,
                ),
                _buildInfoCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Exam Date',
                  value: date,
                  color: Colors.orange,
                ),
                _buildInfoCard(
                  icon: Icons.access_time,
                  title: 'Exam Time',
                  value: time,
                  color: Colors.purple,
                ),

                const SizedBox(height: 24),

                // ── General Notice ────────────────────────────────────────
                const Text(
                  'GENERAL NOTICE',
                  style: TextStyle(
                    color: tealDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NoticeItem(
                        title: 'Authorized Access Only',
                        subtitle:
                            'Invigilators must use official credentials. Sharing login details is strictly prohibited.',
                      ),
                      _NoticeItem(
                        title: 'Correct Exam & Course Selection',
                        subtitle:
                            'Before taking attendance, confirm the correct exam and course are selected.',
                      ),
                      _NoticeItem(
                        title: 'Accurate Attendance Recording',
                        subtitle:
                            'Scan each student ID carefully. Report any discrepancies to the Exams Office immediately.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NoticeItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
