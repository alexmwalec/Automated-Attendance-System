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
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: tealPrimary));
          }

          // Collect all assignments
          final List<Map<String, dynamic>> assignments = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (final doc in snapshot.data!.docs) {
              assignments.add(doc.data() as Map<String, dynamic>);
            }
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

                // ── Assigned Tasks ────────────────────────────────────────
                const Text(
                  'ASSIGNED TASKS',
                  style: TextStyle(
                    color: tealDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Show a card per assignment, or a placeholder if none
                if (assignments.isEmpty)
                  _buildEmptyAssignmentCard()
                else
                  ...assignments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return _buildAssignmentCard(
                      index: index + 1,
                      course: data['course'] ?? 'N/A',
                      venue: data['room'] ?? 'No Venue Assigned',
                      date: data['date'] ?? 'No Date Set',
                      time: data['time'] ?? 'N/A',
                      sessionType: data['sessionType'] ?? 'N/A',
                    );
                  }),

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

  /// A single card that groups all details for one assignment.
  Widget _buildAssignmentCard({
    required int index,
    required String course,
    required String venue,
    required String date,
    required String time,
    required String sessionType,
  }) {
    // Pick a colour/icon for the session-type badge
    final (Color badgeColor, IconData sessionIcon) =
        switch (sessionType.toLowerCase()) {
      'lab' => (Colors.green, Icons.science_outlined),
      'class' => (Colors.blue, Icons.class_outlined),
      _ => (tealPrimary, Icons.assignment_outlined), // default → exam
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: tealPrimary.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                // Session-type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sessionIcon, size: 13, color: badgeColor),
                      const SizedBox(width: 5),
                      Text(
                        sessionType.toUpperCase(),
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Task #$index',
                  style: const TextStyle(
                    color: tealDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Detail rows ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.menu_book_rounded,
                  label: 'Course',
                  value: course,
                  color: tealPrimary,
                ),
                const _RowDivider(),
                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Venue',
                  value: venue,
                  color: Colors.blue,
                ),
                const _RowDivider(),
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: date,
                  color: Colors.orange,
                ),
                const _RowDivider(),
                _buildDetailRow(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: time,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the invigilator has no assignments yet.
  Widget _buildEmptyAssignmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined,
              size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'No tasks assigned yet',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your assignments will appear here once added by a lecturer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// A single label + value row inside an assignment card.
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin divider used between detail rows.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.shade100,
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
