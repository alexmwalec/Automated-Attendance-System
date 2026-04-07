import 'package:flutter/material.dart';

// Using constants from invigilator_dashboard.dart
const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  // Using the teal theme
  static const Color scanBg = tealLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scanBg,
      // Header matching invigilator_dashboard.dart
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: true, // Allows back button if needed
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 70,
        title: const Text(
          'AAS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card matching the "Welcome Back" style
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                border: Border.all(color: tealPrimary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: tealPrimary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.history, size: 28, color: tealPrimary),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance History',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: tealPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'View and manage all attendance records',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Row using the Teal Info Card style
            Row(
              children: [
                Expanded(
                  child: _buildTealStatCard(
                    Icons.assignment,
                    'Total Sessions',
                    '128',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTealStatCard(
                    Icons.pie_chart,
                    'Avg Attendance',
                    '84%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const _SectionHeader(title: "RECENT RECORDS"),
            const SizedBox(height: 10),

            // Your existing table or a placeholder for the history list
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tealPrimary.withOpacity(0.2)),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("History Table Content Goes Here",
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build cards matching the dashboard style
  Widget _buildTealStatCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: tealPrimary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tealPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: tealPrimary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: tealDark,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 0.6,
      ),
    );
  }
}