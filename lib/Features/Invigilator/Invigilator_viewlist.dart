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
          'Attendance Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailBox(attendanceData['sessionType'] ?? 'N/A'),
                _buildDetailBox(attendanceData['courseCode'] ?? 'N/A'),
                _buildDetailBox(attendanceData['date'] ?? 'N/A'),
                _buildDetailBox(
                    '${attendanceData['totalPresent'] ?? 0} Present'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: tealPrimary, thickness: 4),
          _buildTableHeader(["REG NO", "FULL NAME", "STATUS"]),
          Expanded(
            child: ListView.builder(
              itemCount: fullList.length,
              itemBuilder: (context, index) {
                final student = fullList[index];

                // Ensure keys match exactly what was saved in submit_list.dart
                String regNo = student['regNo']?.toString() ?? 'N/A';
                String firstName = student['name']?.toString() ?? 'Unknown';
                String lastName = student['surname']?.toString() ?? '';
                String status = student['status']?.toString() ?? 'Absent';

                // Logic for Status Widget Styling
                Widget statusWidget;
                if (status == 'Present') {
                  statusWidget = const Text('Present',
                      style: TextStyle(
                          fontSize: 10,
                          color: tealDark,
                          fontWeight: FontWeight.bold));
                } else if (status == 'Exit') {
                  statusWidget = const Text('E',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold));
                } else {
                  statusWidget = const Text('Absent',
                      style: TextStyle(fontSize: 10, color: Colors.red));
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black12, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text(regNo,
                              style: const TextStyle(fontSize: 10))),
                      Expanded(
                          flex: 4,
                          child: Text('$firstName $lastName',
                              style: const TextStyle(fontSize: 10))),
                      Expanded(flex: 2, child: statusWidget),
                    ],
                  ),
                );
              },
            ),
          ),
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
        children: [
          Expanded(flex: 3, child: _headerText(headers[0])),
          Expanded(flex: 4, child: _headerText(headers[1])),
          Expanded(flex: 2, child: _headerText(headers[2])),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 11, color: tealDark),
    );
  }
}
