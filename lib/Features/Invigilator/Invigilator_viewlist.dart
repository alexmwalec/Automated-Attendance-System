import 'package:flutter/material.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Attendance Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // --- Header Summary ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDetailBox(attendanceData['courseCode'] ?? 'N/A'),
                _buildDetailBox(attendanceData['sessionType'] ?? 'N/A'),
                _buildDetailBox('${attendanceData['totalPresent'] ?? 0} / ${attendanceData['totalEnrolled'] ?? 0}'),
                _buildDetailBox(attendanceData['date'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: tealPrimary, thickness: 2),
          _buildTableHeader(["REG NO", "FULL NAME", "STATUS"]),

          Expanded(
            child: ListView.builder(
              itemCount: fullList.length,
              itemBuilder: (context, index) {
                final student = fullList[index];

                String regNo = student['regNo']?.toString() ?? 'N/A';
                String fullName = "${student['name'] ?? ''} ${student['surname'] ?? ''}".trim();
                String status = student['status']?.toString() ?? 'Absent';

                bool isPresent = status == 'Present';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(regNo, style: const TextStyle(fontSize: 11))),
                      Expanded(flex: 4, child: Text(fullName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                      Expanded(
                          flex: 2,
                          child: Text(
                            status,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPresent ? tealPrimary : Colors.red,
                            ),
                          )
                      ),
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

  Widget _buildDetailBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tealPrimary),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tealDark),
      ),
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Container(
      color: Colors.teal.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText(headers[0])),

          Expanded(flex: 4, child: _headerText(headers[1])),
          Expanded(flex: 2, child: _headerText(headers[2], textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _headerText(String text, {TextAlign textAlign = TextAlign.left}) {
    return Text(
      text,
      textAlign: textAlign,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: tealDark),
    );
  }
}