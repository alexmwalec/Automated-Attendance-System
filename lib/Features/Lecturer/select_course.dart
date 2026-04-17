import 'package:automated_attendance_system/Features/Lecturer/take_attendance.dart';
import 'package:flutter/material.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);
const Color tealAccent = Color(0xFF26A69A);

class Course extends StatelessWidget {
  const Course({super.key});

  @override
  Widget build(BuildContext context) {
    return const CourseSelectionScreen();
  }
}

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  String? selectedSessionType;
  String? selectedCourse;

  final List<String> sessionTypes = ['Class', 'Lab', 'Exam'];

  final List<Map<String, String>> courses = [
    {'code': 'COM 323', 'year': '3 Year'},
    {'code': 'COM 321', 'year': '3 Year'},
    {'code': 'COM 325', 'year': '3 Year'},
    {'code': 'COM 330', 'year': '4 Year'},
    {'code': 'COM J23', 'year': '3 Year'},
    {'code': 'COM S21', 'year': '3 Year'},
    {'code': 'COM 401', 'year': '4 Year'},
    {'code': 'COM 402', 'year': '4 Year'},
    {'code': 'COM 403', 'year': '4 Year'},
    {'code': 'COM 404', 'year': '4 Year'},
    {'code': 'COM 405', 'year': '4 Year'},
    {'code': 'COM 406', 'year': '4 Year'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: Border.all(color: tealPrimary.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(text: 'Select '),
                  TextSpan(
                    text: 'course',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'session type',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' before proceeding to recording attendance',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // SESSION TYPE Label
          const Text(
            'SESSION TYPE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: tealDark,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 10),

          // Session Type Buttons Row
          Row(
            children: sessionTypes.map((type) {
              final isSelected = selectedSessionType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSessionType = type;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? tealPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? tealPrimary : Colors.grey.shade400,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Course Grid (3 columns)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final isSelected = selectedCourse == course['code'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCourse = course['code'];
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tealPrimary.withOpacity(0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? tealPrimary : Colors.grey.shade300,
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        course['code']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? tealPrimary : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['year']!,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isSelected ? tealPrimary : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Proceed Button - wider, aligned to the right
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedSessionType != null && selectedCourse != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendancePage(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select both session type and course',
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Proceed to scanning',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
