import 'package:flutter/material.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFF4F9F8);

class ViewList extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const ViewList({super.key, required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    final List fullList = attendanceData['fullAttendanceList'] ?? [];

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Attendance Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: tealPrimary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(attendanceData['courseCode'] ?? 'N/A', 'Course'),
                _buildStat(attendanceData['sessionType'] ?? 'N/A', 'Type'),
                _buildStat('${attendanceData['totalPresent'] ?? 0}', 'Present'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text("REG NO", style: TextStyle(fontWeight: FontWeight.bold, color: tealDark, fontSize: 12))),
                Expanded(flex: 4, child: Text("NAME", style: TextStyle(fontWeight: FontWeight.bold, color: tealDark, fontSize: 12))),
                Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, color: tealDark, fontSize: 12))),
              ],
            ),
          ),
          const Divider(indent: 20, endIndent: 20),

          // Student List
          Expanded(
            child: ListView.builder(
              itemCount: fullList.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final student = fullList[index];
                String status = student['status'] ?? 'Absent';

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(student['regNo'] ?? 'N/A', style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 4, child: Text('${student['name']} ${student['surname']}', style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 2, child: _statusChip(status)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'Present' ? tealPrimary : (status == 'Exit' ? Colors.green : Colors.red);
    String label = status == 'Exit' ? 'E' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}