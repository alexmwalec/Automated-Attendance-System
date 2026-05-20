import 'dart:async';
import 'package:flutter/material.dart';import 'package:cloud_firestore/cloud_firestore.dart';
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

  String? _selectedRoom; // Stores the selected room from dropdown
  final List<String> _assignedInvigilators = [];
  bool _isAssigning = false;

  @override
  void dispose() {
    _invigilatorController.dispose();
    super.dispose();
  }

  void _addInvigilator() {
    final name = _invigilatorController.text.trim(); // Always trim whitespace
    if (name.isNotEmpty) {
      setState(() {
        if (!_assignedInvigilators.contains(name)) {
          _assignedInvigilators.add(name);
        }
        _invigilatorController.clear();
      });
    }
  }
  Future<void> _submitAssignment() async {
    if (_formKey.currentState!.validate()) {
      if (_assignedInvigilators.isEmpty && _invigilatorController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add at least one invigilator")));
        return;
      }
      if (_invigilatorController.text.isNotEmpty) _addInvigilator();

      setState(() => _isAssigning = true);

      try {
        await FirebaseFirestore.instance.collection('exam_assignments').add({
          'course': widget.courseCode ?? 'N/A',
          'sessionType': widget.sessionType ?? 'N/A',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'time': TimeOfDay.now().format(context),
          'room': _selectedRoom, // Using the dropdown value
          'invigilators': _assignedInvigilators,
          'lecturerId': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Assigned',
        });

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Task Assigned to Invigilators'),
              backgroundColor: tealPrimary),
        );
      } catch (e) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
              const SizedBox(height:16),

              const Text('ROOM / VENUE',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tealDark)),
              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator(color: tealPrimary);
                  }

                  List<DropdownMenuItem<String>> roomItems = snapshot.data!.docs.map((doc) {
                    String roomName = doc.id;
                    return DropdownMenuItem(
                      value: roomName,
                      child: Text(roomName),
                    );
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedRoom,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    hint: const Text("Select a Room"),
                    items: roomItems,
                    onChanged: (val) => setState(() => _selectedRoom = val),
                    validator: (v) => v == null ? 'Please select a room' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text('INVIGILATORS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tealDark)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                        controller: _invigilatorController,
                        decoration: const InputDecoration(
                            hintText: 'Enter Invigilator Name',
                            fillColor: Colors.white,
                            filled: true)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addInvigilator,
                    icon: const Icon(Icons.add_circle, color: tealPrimary, size: 35),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _assignedInvigilators
                    .map((name) => Chip(
                  label: Text(name),
                  onDeleted: () => setState(
                          () => _assignedInvigilators.remove(name)),
                ))
                    .toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isAssigning ? null : _submitAssignment,
                  style: ElevatedButton.styleFrom(backgroundColor: tealPrimary),
                  child: _isAssigning
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Assignment',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildReadOnlyField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text(value)),
    ]);
  }
}