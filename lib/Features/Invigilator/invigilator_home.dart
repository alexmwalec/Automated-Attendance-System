import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvigilatorHome extends StatelessWidget {
  const InvigilatorHome({super.key});

  static const Color primaryColor = Color(0xFF2E9E8E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'AAS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
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
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          final List<Map<String, dynamic>> assignments = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (final doc in snapshot.data!.docs) {
              assignments.add(doc.data() as Map<String, dynamic>);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WELCOME CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
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
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Manage exam attendance and monitor assigned sessions.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ASSIGNED TASKS TITLE
                const Text(
                  'ASSIGNED TASKS',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // FIRST CARD
                _AssignmentCard(
                  course: assignments.isNotEmpty
                      ? (assignments[0]['course'] ?? 'N/A')
                      : 'Not Assigned',
                  venue: assignments.isNotEmpty
                      ? (assignments[0]['room'] ?? 'N/A')
                      : '—',
                  date: assignments.isNotEmpty
                      ? (assignments[0]['date'] ?? 'N/A')
                      : '—',
                  time: assignments.isNotEmpty
                      ? (assignments[0]['time'] ?? 'N/A')
                      : '—',
                  sessionType: assignments.isNotEmpty
                      ? (assignments[0]['sessionType'] ?? 'N/A')
                      : '—',
                ),

                const SizedBox(height: 10),

                // SECOND CARD
                _AssignmentCard(
                  course: assignments.length >= 2
                      ? (assignments[1]['course'] ?? 'N/A')
                      : 'Not Assigned',
                  venue: assignments.length >= 2
                      ? (assignments[1]['room'] ?? 'N/A')
                      : '—',
                  date: assignments.length >= 2
                      ? (assignments[1]['date'] ?? 'N/A')
                      : '—',
                  time: assignments.length >= 2
                      ? (assignments[1]['time'] ?? 'N/A')
                      : '—',
                  sessionType: assignments.length >= 2
                      ? (assignments[1]['sessionType'] ?? 'N/A')
                      : '—',
                ),

                const SizedBox(height: 20),

                // NOTICE TITLE
                const Text(
                  'GENERAL NOTICE',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // NOTICE CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.12),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NoticeItem(
                        title: 'Authorized Access Only',
                        subtitle:
                            'Invigilators must use official credentials. Sharing login details is prohibited.',
                      ),
                      _NoticeItem(
                        title: 'Correct Exam Selection',
                        subtitle:
                            'Always confirm the correct exam and course before attendance scanning.',
                      ),
                      _NoticeItem(
                        title: 'Accurate Attendance',
                        subtitle:
                            'Scan student IDs carefully and report any discrepancies immediately.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ASSIGNMENT CARD

class _AssignmentCard extends StatelessWidget {
  final String course;
  final String venue;
  final String date;
  final String time;
  final String sessionType;

  const _AssignmentCard({
    required this.course,
    required this.venue,
    required this.date,
    required this.time,
    required this.sessionType,
  });

  static const Color primaryColor = Color(0xFF2E9E8E);

  @override
  Widget build(BuildContext context) {
    final bool isAssigned = course != 'Not Assigned';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COURSE HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  course,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAssigned ? primaryColor : Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // FIRST ROW
          Row(
            children: [
              Expanded(
                child: _CompactDetail(
                  title: 'Venue',
                  value: venue,
                ),
              ),
              Expanded(
                child: _CompactDetail(
                  title: 'Date',
                  value: date,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // SECOND ROW
          Row(
            children: [
              Expanded(
                child: _CompactDetail(
                  title: 'Time',
                  value: time,
                ),
              ),
              Expanded(
                child: _CompactDetail(
                  title: 'Session',
                  value: sessionType,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// COMPACT DETAIL ITEM

class _CompactDetail extends StatelessWidget {
  final String title;
  final String value;

  const _CompactDetail({
    required this.title,
    required this.value,
  });

  static const Color primaryColor = Color(0xFF2E9E8E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primaryColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// NOTICE ITEM

class _NoticeItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NoticeItem({
    required this.title,
    required this.subtitle,
  });

  static const Color primaryColor = Color(0xFF2E9E8E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
