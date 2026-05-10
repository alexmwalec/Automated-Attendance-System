import 'package:flutter/material.dart';
import 'lecturer_dashboard.dart';
import 'attendance_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

class Assign extends StatefulWidget {
  const Assign({super.key});

  @override
  State<Assign> createState() => _AssignState();
}

class _AssignState extends State<Assign> {
  final int _currentIndex = 3;

  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _roomController = TextEditingController();
  final _invigilatorController = TextEditingController();

  Map<String, String>? _confirmedRow;
  bool _isAssigning = false; // To show loading state

  @override
  void dispose() {
    _courseController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _roomController.dispose();
    _invigilatorController.dispose();
    super.dispose();
  }


  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: tealPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateController.text =
      '${picked.day} ${_monthName(picked.month)}, ${picked.year}';
    }
  }


  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: tealPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      _timeController.text = '$hour:$minute $period';
    }
  }

  String _monthName(int m) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[m];
  }

  void _onAssign() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isAssigning = true);

      try {
        final assignmentData = {
          'course': _courseController.text.trim(),
          'date': _dateController.text.trim(),
          'time': _timeController.text.trim(),
          'room': _roomController.text.trim(),
          'invigilatorName': _invigilatorController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Assigned',
        };

        // 2. Add to Firestore collection 'exam_assignments'
        await FirebaseFirestore.instance
            .collection('exam_assignments')
            .add(assignmentData);


        setState(() {
          _confirmedRow = {
            'course': _courseController.text.trim(),
            'date': _dateController.text.trim(),
            'time': _timeController.text.trim(),
            'room': _roomController.text.trim(),
            'invigilator': _invigilatorController.text.trim(),
          };
          _isAssigning = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assigned and synced to Invigilator Dashboard!'),
            backgroundColor: tealPrimary,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        setState(() => _isAssigning = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Bottom nav tap ────────────────────────────────────────────────────────
  void _onNavTap(int i) {
    if (i == _currentIndex) return;

    if (i == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LecturerDashboard(initialIndex: 0)),
            (route) => false,
      );
    } else if (i == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LecturerDashboard(initialIndex: 1)),
            (route) => false,
      );
    } else if (i == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceHistory()),
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
        toolbarHeight: 60,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'AAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tealDark,
                    border: Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign Invigilator',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tealPrimary),
              ),
              const SizedBox(height: 24),

              _buildFormField(
                label: 'COURSE',
                controller: _courseController,
                hint: 'Enter course name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'DATE',
                controller: _dateController,
                hint: 'Select date',
                readOnly: true,
                onTap: _pickDate,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                suffixIcon: const Icon(Icons.calendar_today, size: 18, color: tealPrimary),
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'TIME',
                controller: _timeController,
                hint: 'Select time',
                readOnly: true,
                onTap: _pickTime,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                suffixIcon: const Icon(Icons.access_time, size: 18, color: tealPrimary),
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'ROOM',
                controller: _roomController,
                hint: 'Enter room number',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'INVIGILATOR',
                controller: _invigilatorController,
                hint: 'Enter invigilator name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tealPrimary.withOpacity(0.2)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.55),
                    children: [
                      const TextSpan(
                        text: 'Before confirming, ensure that the exam details are correct, '
                            'the invigilator is available at the selected time, the venue is '
                            'correct, and no scheduling conflict exists. ',
                      ),
                      TextSpan(
                        text: 'Submit the form only after verifying all information.',
                        style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 120,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isAssigning ? null : _onAssign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 2,
                    ),
                    child: _isAssigning
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Assign', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_confirmedRow != null)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tealPrimary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Successfully!',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tealPrimary),
                      ),
                      const SizedBox(height: 8),
                      _buildConfirmationRow('Course:', _confirmedRow!['course']!),
                      _buildConfirmationRow('Date:', _confirmedRow!['date']!),
                      _buildConfirmationRow('Time:', _confirmedRow!['time']!),
                      _buildConfirmationRow('Room:', _confirmedRow!['room']!),
                      _buildConfirmationRow('Invigilator:', _confirmedRow!['invigilator']!),
                    ],
                  ),
                ),
            ],
          ),
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
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Assign Task'),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tealDark)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: tealPrimary.withOpacity(0.3))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: tealPrimary.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: tealPrimary, width: 1.5)),
            errorStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tealDark)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }
}