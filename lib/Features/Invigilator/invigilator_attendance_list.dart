import 'package:flutter/material.dart';

class InvigilatorAttendanceList extends StatelessWidget {
  const InvigilatorAttendanceList({super.key});

  static const Color tealPrimary = Color(0xFF2E9E8E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tealPrimary,
        title: const Text('Attendance List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 15,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: tealPrimary.withOpacity(0.1),
              child: Text('${index + 1}', style: const TextStyle(color: tealPrimary, fontWeight: FontWeight.bold)),
            ),
            title: Text('Student Name ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: BAF-CS-2024-00${index + 1}'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          );
        },
      ),
    );
  }
}
