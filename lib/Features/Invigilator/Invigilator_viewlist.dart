import 'package:flutter/material.dart';
import 'invigilator_attendance_list.dart';
import 'invigilator_home.dart';

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
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Attendance List',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          // Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: tealPrimary.withOpacity(0.1),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Reg No',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tealDark))),
                Expanded(
                    flex: 4,
                    child: Text('Full Name',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tealDark))),
                SizedBox(
                    width: 40,
                    child: Text('Status',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tealDark),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Colors.black12),

          Expanded(
            child: ListView.builder(
              itemCount: fullList.length,
              itemBuilder: (context, i) {
                final s = fullList[i];
                final bool isPresent = s['status'] == 'Present';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(bottom: BorderSide(color: Colors.black12))),
                  child: Row(children: [
                    Expanded(
                        flex: 3,
                        child: Text(s['regNo'] ?? '',
                            style: const TextStyle(fontSize: 11))),
                    Expanded(
                        flex: 4,
                        child: Text("${s['name']} ${s['surname']}",
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500))),
                    SizedBox(
                      width: 40,
                      child: Text(s['status'] ?? '',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPresent ? tealPrimary : Colors.red)),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
