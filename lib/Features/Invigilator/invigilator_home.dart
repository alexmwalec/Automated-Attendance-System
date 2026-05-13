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

                // ── Assigned Tasks label ──────────────────────────────────
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

                // First card — real data or assigned placeholder
                if (assignments.isNotEmpty)
                  _AssignmentCard(
                    course: assignments[0]['course'] ?? 'N/A',
                    venue: assignments[0]['room'] ?? 'N/A',
                    date: assignments[0]['date'] ?? 'N/A',
                    time: assignments[0]['time'] ?? 'N/A',
                    sessionType: assignments[0]['sessionType'] ?? 'N/A',
                    isAssigned: true,
                  )
                else
                  const _AssignmentCard(
                    course: 'N/A',
                    venue: 'N/A',
                    date: 'N/A',
                    time: 'N/A',
                    sessionType: 'N/A',
                    isAssigned: true,
                  ),

                const SizedBox(height: 14),

                // Second card — real second task or unassigned placeholder
                if (assignments.length >= 2)
                  _AssignmentCard(
                    course: assignments[1]['course'] ?? 'N/A',
                    venue: assignments[1]['room'] ?? 'N/A',
                    date: assignments[1]['date'] ?? 'N/A',
                    time: assignments[1]['time'] ?? 'N/A',
                    sessionType: assignments[1]['sessionType'] ?? 'N/A',
                    isAssigned: true,
                  )
                else
                  const _AssignmentCard(
                    course: 'Not Assigned',
                    venue: '—',
                    date: '—',
                    time: '—',
                    sessionType: '—',
                    isAssigned: false,
                  ),

                // Any extra tasks beyond two
                if (assignments.length > 2)
                  ...assignments.skip(2).map(
                        (data) => Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _AssignmentCard(
                            course: data['course'] ?? 'N/A',
                            venue: data['room'] ?? 'N/A',
                            date: data['date'] ?? 'N/A',
                            time: data['time'] ?? 'N/A',
                            sessionType: data['sessionType'] ?? 'N/A',
                            isAssigned: true,
                          ),
                        ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Assignment Card  — matches the design in the screenshot
// ─────────────────────────────────────────────────────────────────────────────

class _AssignmentCard extends StatelessWidget {
  final String course;
  final String venue;
  final String date;
  final String time;
  final String sessionType;
  final bool isAssigned;

  const _AssignmentCard({
    required this.course,
    required this.venue,
    required this.date,
    required this.time,
    required this.sessionType,
    required this.isAssigned,
  });

  static const Color tealPrimary = Color(0xFF2E9E8E);
  static const Color tealDark = Color(0xFF227A6D);

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isAssigned ? tealPrimary : Colors.grey.shade400;
    final Color textColor = isAssigned ? Colors.black87 : Colors.grey.shade400;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isAssigned ? tealPrimary.withOpacity(0.55) : Colors.grey.shade300,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Course row ───────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Text(
                course,
                style: TextStyle(
                  color: isAssigned ? tealDark : Colors.grey.shade400,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Four detail columns ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetailCol(
                icon: Icons.location_on_outlined,
                label: 'Venue',
                value: venue,
                accentColor: accentColor,
                textColor: textColor,
              ),
              _DetailCol(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: date,
                accentColor: accentColor,
                textColor: textColor,
              ),
              _DetailCol(
                icon: Icons.access_time_rounded,
                label: 'Time',
                value: time,
                accentColor: accentColor,
                textColor: textColor,
              ),
              _DetailCol(
                icon: Icons.assignment_outlined,
                label: 'Session Type',
                value: sessionType,
                accentColor: accentColor,
                textColor: textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Column — icon + bold label + value
// ─────────────────────────────────────────────────────────────────────────────

class _DetailCol extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color textColor;

  const _DetailCol({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: accentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Value
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notice Item
// ─────────────────────────────────────────────────────────────────────────────

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
