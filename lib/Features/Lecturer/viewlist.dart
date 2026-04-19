import 'package:flutter/material.dart';
import 'invigilator_dashboard.dart';
import 'attendance_history.dart';
import 'assign.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class ViewList extends StatefulWidget {
  const ViewList({super.key});

  @override
  State<ViewList> createState() => _ViewListState();
}

class _ViewListState extends State<ViewList> {
  int _currentIndex = 2; // Keep Attendance History tab highlighted

  final List<Map<String, String>> presentStudents = [
    {
      "reg": "bed-com-27-22",
      "name": "Sulphuric moyo",
      "status": "Present"
    },
    {
      "reg": "BSC",
      "name": "King Sley",
      "status": "Present"
    },
  ];

  final List<Map<String, String>> absentStudents = [
    {
      "reg": "bed-com-27-22",
      "name": "Sulphuric moyo",
      "status": "Absent",
      "reason": "Approved"
    },
    {
      "reg": "BED",
      "name": "Alex",
      "status": "Absent",
      "reason": "Not Approved"
    },
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InvigilatorDashboard(initialIndex: 0)),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const InvigilatorDashboard(initialIndex: 1)),
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceHistory()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Assign()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'AAS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.teal,
              radius: 15,
              child: Icon(Icons.person_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 80,
              width: double.infinity,
              color: Colors.white.withOpacity(0.5),
              margin: const EdgeInsets.all(16),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailBox("Class"),
                  _buildDetailBox("Com 411"),
                  _buildDetailBox("11 March"),
                  _buildDetailBox("08:30"),
                  _buildDetailBox("Ck 2"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: tealPrimary, thickness: 8),
            
            // Present Table
            _buildTableHeader(["REG NO", "FULL NAME", "STATUS"]),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: presentStudents.length,
              itemBuilder: (context, index) {
                final student = presentStudents[index];
                return _buildTableRow([student["reg"]!, student["name"]!, student["status"]!]);
              },
            ),

            const Divider(color: tealPrimary, thickness: 2, indent: 16, endIndent: 16),

            // Absent Table
            _buildTableHeader(["REG NO", "FULL NAME", "STATUS", "REASON"]),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: absentStudents.length,
              itemBuilder: (context, index) {
                final student = absentStudents[index];
                return _buildTableRow([
                  student["reg"]!,
                  student["name"]!,
                  student["status"]!,
                  student["reason"]!
                ]);
              },
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading attendance list...'),
                        backgroundColor: tealPrimary,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: tealPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      "Download",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Attendance History'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Assign Task'),
        ],
      ),
    );
  }

  Widget _buildDetailBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTableHeader(List<String> headers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: headers
            .map((h) => Expanded(
                  child: Text(
                    h,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTableRow(List<String> cells) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: cells
            .map((c) => Expanded(
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 9),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
