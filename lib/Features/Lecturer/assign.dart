import 'package:flutter/material.dart';
import 'invigilator_dashboard.dart';
import 'attendance_history.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFDFF2EF);

// ─── Assign Invigilator Page ──────────────────────────────────────────────────
class Assign extends StatefulWidget {
  const Assign({super.key});

  @override
  State<Assign> createState() => _AssignState();
}

class _AssignState extends State<Assign> {
  final int _currentIndex = 3;

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _roomController = TextEditingController();
  final _invigilatorController = TextEditingController();

  Map<String, String>? _confirmedRow;

  @override
  void dispose() {
    _courseController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _roomController.dispose();
    _invigilatorController.dispose();
    super.dispose();
  }

  // ── Date picker ───────────────────────────────────────────────────────────
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

  // ── Time picker ───────────────────────────────────────────────────────────
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
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[m];
  }

  // ── Assign button handler ─────────────────────────────────────────────────
  void _onAssign() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _confirmedRow = {
          'course': _courseController.text.trim(),
          'date': _dateController.text.trim(),
          'time': _timeController.text.trim(),
          'room': _roomController.text.trim(),
          'invigilator': _invigilatorController.text.trim(),
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invigilator assigned successfully!'),
          backgroundColor: tealPrimary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Bottom nav tap ────────────────────────────────────────────────────────
  void _onNavTap(int i) {
    if (i == _currentIndex) return;

    if (i == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const InvigilatorDashboard(initialIndex: 0),
        ),
        (route) => false,
      );
    } else if (i == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const InvigilatorDashboard(initialIndex: 1),
        ),
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

      // ── AppBar ─────────────────────────────────────────────────────────────
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
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
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
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign Invigilator',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tealPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // ── Table card ────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tealPrimary.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: tealPrimary.withOpacity(0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Header row
                    Container(
                      color: tealPrimary,
                      child: const Row(
                        children: [
                          _TH('COURSE', flex: 2),
                          _TH('DATE', flex: 3),
                          _TH('TIME', flex: 2),
                          _TH('ROOM', flex: 1),
                          _TH('INVIGILATOR', flex: 2),
                        ],
                      ),
                    ),

                    // Input row
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _TableInput(
                              controller: _courseController,
                              hint: 'COM 432',
                              validator: (v) =>
                                  v == null || v.isEmpty ? '*' : null,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _TableInput(
                              controller: _dateController,
                              hint: 'Pick date',
                              readOnly: true,
                              onTap: _pickDate,
                              validator: (v) =>
                                  v == null || v.isEmpty ? '*' : null,
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: tealPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TableInput(
                              controller: _timeController,
                              hint: 'Pick time',
                              readOnly: true,
                              onTap: _pickTime,
                              validator: (v) =>
                                  v == null || v.isEmpty ? '*' : null,
                              suffixIcon: const Icon(
                                Icons.access_time,
                                size: 12,
                                color: tealPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: _TableInput(
                              controller: _roomController,
                              hint: 'CK2',
                              validator: (v) =>
                                  v == null || v.isEmpty ? '*' : null,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TableInput(
                              controller: _invigilatorController,
                              hint: 'Name',
                              validator: (v) =>
                                  v == null || v.isEmpty ? '*' : null,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Confirmed data row
                    if (_confirmedRow != null)
                      Container(
                        color: const Color(0xFFF0FAF9),
                        child: Row(
                          children: [
                            _TD(_confirmedRow!['course']!, flex: 2),
                            _TD(_confirmedRow!['date']!, flex: 3),
                            _TD(_confirmedRow!['time']!, flex: 2),
                            _TD(_confirmedRow!['room']!, flex: 1),
                            _TD(_confirmedRow!['invigilator']!, flex: 2),
                          ],
                        ),
                      ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Note text ─────────────────────────────────────────────────
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.55,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Before confirming, ensure that the exam details are correct, '
                          'the invigilator is available at the selected time, the venue is '
                          'correct, and no scheduling conflict exists. Submit the form only '
                          'after verifying all information. ',
                    ),
                    TextSpan(
                      text:
                          'Assign the Invigilator only after verifying all information.',
                      style: TextStyle(
                        color: Colors.redAccent.shade200,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Assign button ─────────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 100,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _onAssign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Assign',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: tealPrimary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Attendance History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Assign Task',
          ),
        ],
      ),
    );
  }
}

// ─── Table Header Cell ────────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

// ─── Table Data Cell ──────────────────────────────────────────────────────────
class _TD extends StatelessWidget {
  final String text;
  final int flex;
  const _TD(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 9.5, color: Colors.black87),
        ),
      ),
    );
  }
}

// ─── Inline Table Input Field ─────────────────────────────────────────────────
class _TableInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _TableInput({
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        style: const TextStyle(fontSize: 9.5, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
          suffixIcon: suffixIcon,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 20, minHeight: 20),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: tealPrimary.withOpacity(0.4), width: 1),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: tealPrimary, width: 1.5),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
          errorStyle: const TextStyle(fontSize: 7, height: 0.8),
        ),
      ),
    );
  }
}
