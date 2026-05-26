import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Invigilator_viewlist.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealLight = Color(0xFFDFF2EF);

class InvigilatorAttendanceList extends StatefulWidget {
  const InvigilatorAttendanceList({super.key});
  @override
  State<InvigilatorAttendanceList> createState() => _InvigilatorAttendanceListState();
}

class _InvigilatorAttendanceListState extends State<InvigilatorAttendanceList> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
    setState(() => _userName = "${doc.data()?['name']} ${doc.data()?['surname']}".trim());
  }

  @override
  Widget build(BuildContext context) {
    if (_userName == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(backgroundColor: tealPrimary, automaticallyImplyLeading: false, title: const Text('SUBMISSION HISTORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('attendance').where('submittedBy', isEqualTo: _userName).orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No records submitted yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.history, color: tealPrimary),
                  title: Text("${data['courseCode']} - ${data['sessionType']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${data['date']} • ${data['totalPresent']} Present"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewList(attendanceData: data))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}