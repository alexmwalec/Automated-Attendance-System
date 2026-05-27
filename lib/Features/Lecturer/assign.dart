import 'dart:async';import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class Assign extends StatefulWidget {
  final String? courseCode;
  final String? sessionType;

  const Assign({super.key, this.courseCode, this.sessionType});

  @override
  State<Assign> createState() => _AssignState();
}

class _AssignState extends State<Assign> {
  final _formKey = GlobalKey<FormState>();
  final _invigilatorController = TextEditingController();

  String? _selectedRoom;
  String? _selectedInvigilatorId; // NEW: To store the UID
  String? _selectedInvigilatorName; // NEW: To store the Full Name

  bool _isAssigning = false;
  List<Map<String, dynamic>> _userSuggestions = [];

  @override
  void dispose() {
    _invigilatorController.dispose();
    super.dispose();
  }

  // NEW: Fetch real users from 'users' collection for the dropdown
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    return snap.docs.map((d) => {
      'id': d.id,
      'name': "${d.data()['name'] ?? ''} ${d.data()['surname'] ?? ''}".trim()
    }).toList();
  }

  Future<void> _submitAssignment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedInvigilatorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a valid invigilator from the system")));
        return;
      }

      setState(() => _isAssigning = true);

      try {
        await FirebaseFirestore.instance.collection('exam_assignments').add({
          'course': widget.courseCode ?? 'N/A',
          'sessionType': widget.sessionType ?? 'N/A',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'time': TimeOfDay.now().format(context),
          'room': _selectedRoom,
          'invigilatorId': _selectedInvigilatorId, // REQUIRED for Invigilator Home query
          'invigilatorName': _selectedInvigilatorName,
          'lecturerId': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Assigned',
        });

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task Assigned Successfully'), backgroundColor: tealPrimary),
        );
      } catch (e) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        title: const Text('Assign Staff', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyField('COURSE', widget.courseCode ?? 'N/A'),
              const SizedBox(height: 16),
              _buildReadOnlyField('SESSION TYPE', widget.sessionType ?? 'N/A'),
              const SizedBox(height: 16),

              const Text('ROOM / VENUE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tealDark)),
              const SizedBox(height: 8),
              _buildRoomDropdown(),

              const SizedBox(height: 16),
              const Text('INVIGILATOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tealDark)),
              const SizedBox(height: 8),
              _buildInvigilatorDropdown(),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isAssigning ? null : _submitAssignment,
                  style: ElevatedButton.styleFrom(backgroundColor: tealPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isAssigning
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator(color: tealPrimary);
        return DropdownButtonFormField<String>(
          value: _selectedRoom,
          decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          hint: const Text("Select Room"),
          items: snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.id))).toList(),
          onChanged: (val) => setState(() => _selectedRoom = val),
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildInvigilatorDropdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator(color: tealPrimary);
        return DropdownButtonFormField<String>(
          value: _selectedInvigilatorId,
          decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          hint: const Text("Select Staff Member"),
          items: snapshot.data!.map((u) => DropdownMenuItem(value: u['id'].toString(), child: Text(u['name']))).toList(),
          onChanged: (val) {
            final user = snapshot.data!.firstWhere((element) => element['id'] == val);
            setState(() {
              _selectedInvigilatorId = val;
              _selectedInvigilatorName = user['name'];
            });
          },
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 4),
      Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
    ]);
  }
}