import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class InvigilatorAttendanceList extends StatefulWidget {
  const InvigilatorAttendanceList({super.key});

  @override
  State<InvigilatorAttendanceList> createState() => _InvigilatorAttendanceListState();
}

class _InvigilatorAttendanceListState extends State<InvigilatorAttendanceList> {
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
  }

  Future<void> _fetchCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            _currentUserName = "${userDoc.data()?['name']} ${userDoc.data()?['surname']}".trim();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Return a loader while name is being fetched
    if (_currentUserName == null) {
      return const Scaffold(
        backgroundColor: tealLight,
        body: Center(child: CircularProgressIndicator(color: tealPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        automaticallyImplyLeading: false,
        title: const Text('Attendance Records',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 2. Query filtered by the logged-in invigilator's name
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('submittedBy', isEqualTo: _currentUserName)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 3. Catch Index errors and show them on the screen
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Database Error: Please ensure you clicked the link in your console to create the index.\n\nDetails: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: tealPrimary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No attendance records found yet.\nRecords will appear here once you submit attendance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: tealDark),
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _SessionCard(attendanceData: data);
            },
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const _SessionCard({required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    final String courseCode = attendanceData['courseCode'] ?? 'N/A';
    final String sessionType = attendanceData['sessionType'] ?? 'N/A';
    final String date = attendanceData['date'] ?? 'N/A';
    final int totalPresent = attendanceData['totalPresent'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: tealPrimary.withOpacity(0.1),
          child: const Icon(Icons.assignment_turned_in, color: tealPrimary),
        ),
        title: Text(
          '$courseCode – $sessionType',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tealDark),
        ),
        subtitle: Text('$date  •  $totalPresent present',
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: tealPrimary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _AttendanceDetailPage(attendanceData: attendanceData),
          ),
        ),
      ),
    );
  }
}

class _AttendanceDetailPage extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const _AttendanceDetailPage({required this.attendanceData});

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
          'AAS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailBox(attendanceData['sessionType'] ?? 'N/A'),
                _detailBox(attendanceData['courseCode'] ?? 'N/A'),
                _detailBox(attendanceData['date'] ?? 'N/A'),
                _detailBox('${attendanceData['totalPresent'] ?? 0} Present'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: tealPrimary, thickness: 4),
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: fullList.length,
              itemBuilder: (context, index) {
                final student = fullList[index];
                final String regNo = student['regNo']?.toString() ?? 'N/A';
                final String firstName = student['name']?.toString() ?? 'Unknown';
                final String lastName = student['surname']?.toString() ?? '';
                final String status = student['status']?.toString() ?? 'Absent';

                Widget statusWidget = Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: status == 'Present' ? tealDark : Colors.red,
                    fontWeight: status == 'Present' ? FontWeight.bold : FontWeight.normal,
                  ),
                );

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(regNo, style: const TextStyle(fontSize: 10))),
                      Expanded(flex: 4, child: Text('$firstName $lastName', style: const TextStyle(fontSize: 10))),
                      Expanded(flex: 2, child: statusWidget),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating CSV Report...')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: tealPrimary),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Download CSV', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tealPrimary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tealDark),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.teal.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText('REG NO')),
          Expanded(flex: 4, child: _headerText('FULL NAME')),
          Expanded(flex: 2, child: _headerText('STATUS')),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: tealDark));
  }
}