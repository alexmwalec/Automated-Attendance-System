import 'package:flutter/material.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class ViewList extends StatelessWidget {
  const ViewList({super.key});

  // Sample student attendance data
  final List<Map<String, String>> students = const [
    {'id': 'CS2001', 'name': 'Alice Banda', 'status': 'Present'},
    {'id': 'CS2002', 'name': 'Brian Phiri', 'status': 'Present'},
    {'id': 'CS2003', 'name': 'Chisomo Mwale', 'status': 'Absent'},
    {'id': 'CS2004', 'name': 'Diana Tembo', 'status': 'Present'},
    {'id': 'CS2005', 'name': 'Edward Lungu', 'status': 'Present'},
    {'id': 'CS2006', 'name': 'Fatima Osman', 'status': 'Absent'},
    {'id': 'CS2007', 'name': 'George Kamau', 'status': 'Present'},
    {'id': 'CS2008', 'name': 'Hannah Moyo', 'status': 'Present'},
    {'id': 'CS2009', 'name': 'Isaac Chirwa', 'status': 'Present'},
    {'id': 'CS2010', 'name': 'Jane Mbewe', 'status': 'Absent'},
  ];

  @override
  Widget build(BuildContext context) {
    final presentCount = students.where((s) => s['status'] == 'Present').length;
    final absentCount = students.where((s) => s['status'] == 'Absent').length;

    return Scaffold(
      backgroundColor: tealLight,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 60,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tealDark,
                    border: Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            const Text(
              'Attendance List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: tealPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'COM411 — Class Session',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 14),

            // ── Summary row ───────────────────────────────────────────────
            Row(
              children: [
                _SummaryChip(
                  label: 'Total',
                  value: '${students.length}',
                  color: tealPrimary,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Present',
                  value: '$presentCount',
                  color: const Color(0xFF43A047),
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Absent',
                  value: '$absentCount',
                  color: const Color(0xFFEF6C00),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Student Table ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tealPrimary.withOpacity(0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Header
                  Container(
                    color: tealPrimary,
                    child: const Row(
                      children: [
                        _TH('#', flex: 1),
                        _TH('STUDENT ID', flex: 2),
                        _TH('NAME', flex: 4),
                        _TH('STATUS', flex: 2),
                      ],
                    ),
                  ),

                  // Rows
                  ...students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value;
                    final isPresent = student['status'] == 'Present';
                    final rowColor =
                        index.isEven ? Colors.white : const Color(0xFFF0FAF9);

                    return Container(
                      color: rowColor,
                      child: Row(
                        children: [
                          _TD('${index + 1}', flex: 1),
                          _TD(student['id']!, flex: 2),
                          _TD(student['name']!, flex: 4),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isPresent
                                      ? const Color(0xFF43A047)
                                          .withOpacity(0.12)
                                      : const Color(0xFFEF6C00)
                                          .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  student['status']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPresent
                                        ? const Color(0xFF43A047)
                                        : const Color(0xFFEF6C00),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Chip ─────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Table Header Cell ────────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

// ─── Table Data Cell ──────────────────────────────────────────────────────────
class _TD extends StatelessWidget {
  final String text;
  final int flex;
  const _TD(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
      ),
    );
  }
}
