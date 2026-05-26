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
      appBar: AppBar(backgroundColor: tealPrimary, iconTheme: const IconThemeData(color: Colors.white), title: const Text('ATTENDANCE REPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _infoBox(attendanceData['courseCode'] ?? 'N/A'),
              _infoBox(attendanceData['date'] ?? 'N/A'),
              _infoBox('${attendanceData['totalPresent'] ?? 0} Present'),
            ]),
          ),
          const Divider(thickness: 2, color: tealPrimary),
          Expanded(
            child: ListView.builder(
              itemCount: fullList.length,
              itemBuilder: (context, i) {
                final s = fullList[i];
                final bool isPresent = s['status'] == 'Present';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black12))),
                  child: Row(children: [
                    Expanded(flex: 3, child: Text(s['regNo'] ?? '', style: const TextStyle(fontSize: 11))),
                    Expanded(flex: 4, child: Text("${s['name']} ${s['surname']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                    Text(s['status'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPresent ? tealPrimary : Colors.red)),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), border: Border.all(color: tealPrimary)), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tealDark)));
}