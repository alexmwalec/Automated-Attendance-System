import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lecturer_dashboard.dart';
import 'attendance_history.dart';

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
  final int _currentIndex = 3;
  final _formKey = GlobalKey<FormState>();

  final _invigilatorController = TextEditingController();
  final _roomController = TextEditingController();

  // List to store multiple assigned invigilators
  final List<String> _assignedInvigilators = [];
  bool _isAssigning = false;

  @override
  void dispose() {
    _invigilatorController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _addInvigilator() {
    final name = _invigilatorController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _assignedInvigilators.add(name);
        _invigilatorController.clear();
      });
    }
  }

  void _removeInvigilator(int index) {
    setState(() => _assignedInvigilators.removeAt(index));
  }

  Future<void> _submitAssignment() async {
    if (_formKey.currentState!.validate()) {
      if (_assignedInvigilators.isEmpty && _invigilatorController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add at least one invigilator")),
        );
        return;
      }

      if (_invigilatorController.text.isNotEmpty) _addInvigilator();

      setState(() => _isAssigning = true);

      try {
        await FirebaseFirestore.instance.collection('exam_assignments').add({
          'course': widget.courseCode ?? 'N/A',
          'sessionType': widget.sessionType ?? 'N/A',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'room': _roomController.text.trim(),
          'invigilators': _assignedInvigilators,
          'lecturerId': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Assigned',
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invigilators Assigned Successfully'), backgroundColor: tealPrimary),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AttendanceHistory()));
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
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assign Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyField('COURSE CODE', widget.courseCode ?? 'Select from Active Sessions'),
              const SizedBox(height: 16),
              _buildReadOnlyField('SESSION TYPE', widget.sessionType ?? 'Select from Active Sessions'),
              const SizedBox(height: 16),

              _buildInputField('ROOM / VENUE', _roomController, 'e.g CK1'),
              const SizedBox(height: 24),

              const Text('ADD INVIGILATORS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tealDark)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _invigilatorController,
                      decoration: InputDecoration(
                        hintText: 'Enter name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              // Fixed: Wrap with null-safe list check to prevent Web TypeError
              Wrap(
                spacing: 8,
                children: (_assignedInvigilators ?? []).asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    onDeleted: () => _removeInvigilator(entry.key),
                    deleteIconColor: Colors.red,
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isAssigning ? null : _submitAssignment,
                  style: ElevatedButton.styleFrom(backgroundColor: tealPrimary, foregroundColor: Colors.white),
                  child: _isAssigning
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
