import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class Assign extends StatefulWidget {
  final String? courseCode;
  final String? sessionType;
  final String? room;
  final String? invigilatorId;
  final String? invigilatorName;
  final String? assignmentId;

  const Assign({
    super.key,
    this.courseCode,
    this.sessionType,
    this.room,
    this.invigilatorId,
    this.invigilatorName,
    this.assignmentId,
  });

  @override
  State<Assign> createState() => _AssignState();
}

class _AssignState extends State<Assign> {
  final _formKey = GlobalKey<FormState>();
  final _invigilatorController = TextEditingController();

  String? _selectedRoom;
  String? _selectedInvigilatorId;
  String? _selectedInvigilatorName;

  bool _isAssigning = false;
  bool _isEditable = true;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.room;
    _selectedInvigilatorId = widget.invigilatorId;
    _selectedInvigilatorName = widget.invigilatorName;
    if (widget.assignmentId != null) {
      _isEditable = false;
    }
  }

  @override
  void dispose() {
    _invigilatorController.dispose();
    super.dispose();
  }

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
        final data = {
          'course': widget.courseCode ?? 'N/A',
          'sessionType': widget.sessionType ?? 'N/A',
          'room': _selectedRoom,
          'invigilatorId': _selectedInvigilatorId,
          'invigilatorName': _selectedInvigilatorName,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.assignmentId == null) {
          data['date'] = DateTime.now().toIso8601String().split('T')[0];
          data['time'] = TimeOfDay.now().format(context);
          data['lecturerId'] = FirebaseAuth.instance.currentUser?.uid;
          data['createdAt'] = FieldValue.serverTimestamp();
          data['status'] = 'Assigned';
          await FirebaseFirestore.instance.collection('exam_assignments').add(data);
        } else {
          await FirebaseFirestore.instance
              .collection('exam_assignments')
              .doc(widget.assignmentId)
              .update(data);
        }

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.assignmentId == null
                  ? 'Task Assigned Successfully'
                  : 'Assignment Updated Successfully'),
              backgroundColor: tealPrimary),
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
        actions: [
          if (widget.assignmentId != null)
            IconButton(
              icon: Icon(_isEditable ? Icons.close : Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditable = !_isEditable),
            )
        ],
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
              if (_isEditable)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isAssigning ? null : _submitAssignment,
                    style: ElevatedButton.styleFrom(backgroundColor: tealPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _isAssigning
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(widget.assignmentId == null ? 'Confirm Assignment' : 'Update Assignment', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          decoration: InputDecoration(
            filled: true,
            fillColor: _isEditable ? Colors.white : Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabled: _isEditable,
          ),
          hint: const Text("Select Room"),
          items: snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.id))).toList(),
          onChanged: _isEditable ? (val) => setState(() => _selectedRoom = val) : null,
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
          decoration: InputDecoration(
            filled: true,
            fillColor: _isEditable ? Colors.white : Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabled: _isEditable,
          ),
          hint: const Text("Select Staff Member"),
          items: snapshot.data!.map((u) => DropdownMenuItem(value: u['id'].toString(), child: Text(u['name']))).toList(),
          onChanged: _isEditable ? (val) {
            final user = snapshot.data!.firstWhere((element) => element['id'] == val);
            setState(() {
              _selectedInvigilatorId = val;
              _selectedInvigilatorName = user['name'];
            });
          } : null,
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
