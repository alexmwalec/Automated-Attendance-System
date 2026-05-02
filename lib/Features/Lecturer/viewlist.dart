import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class ViewList extends StatelessWidget {
  // Pass the record data from the History screen to this view
  final Map<String, dynamic> attendanceData;

  const ViewList({super.key, required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    // Extract students array from Firestore document data
    final List students = attendanceData['presentStudents'] ?? [];

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Attendance Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Dynamic Header Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailBox(attendanceData['sessionType'] ?? 'N/A'),
                _buildDetailBox(attendanceData['courseCode'] ?? 'N/A'),
                _buildDetailBox(attendanceData['date'] ?? 'N/A'),
                _buildDetailBox('${students.length} Present'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: tealPrimary, thickness: 4),

          // Table Header
          _buildTableHeader(["REG NO", "FULL NAME", "STATUS"]),

          // Students List
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return _buildTableRow([
                  student['regNo'] ?? '',
                  '${student['name']} ${student['surname']}',
                  'Present'
                ]);
              },
            ),
          ),

          // Download Action
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating PDF Report...')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: tealPrimary),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text("Download CSV",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tealPrimary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: tealDark),
      ),
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Container(
      color: Colors.teal.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: headers
            .map((h) => Expanded(
          child: Text(
            h,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: tealDark),
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildTableRow(List<String> cells) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: cells
            .map((c) => Expanded(
          child: Text(
            c,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
        ))
            .toList(),
      ),
    );
  }
}
