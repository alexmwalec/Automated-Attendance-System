import 'package:automated_attendance_system/Features/Lecturer/take_attendance.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  String? selectedSessionType;
  String? selectedCourse;
  List<Map<String, String>> assignedCourses = [];
  bool isLoading = true;
  final List<String> sessionTypes = ['Class', 'Lab', 'Exam'];

  @override
  void initState() {
    super.initState();
    fetchLecturerCourses();
  }

  Future<void> fetchLecturerCourses() async {
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => isLoading = false);
        return;
      }

      var lectDoc = await FirebaseFirestore.instance.collection('lecturers').doc(uid).get();

      if (lectDoc.exists) {
        List<dynamic> rawList = lectDoc.data()?['assignedCourses'] ?? [];
        List<String> courseCodes = [];

        // Handle ["COM 423 , INF423"] comma separated string format
        for (var item in rawList) {
          String val = item.toString();
          if (val.contains(',')) {
            courseCodes.addAll(val.split(',').map((e) => e.trim()));
          } else {
            courseCodes.add(val.trim());
          }
        }

        List<Map<String, String>> temp = [];
        for (String code in courseCodes) {
          if (code.isEmpty) continue;
          var courseDoc = await FirebaseFirestore.instance.collection('courses').doc(code).get();
          temp.add({
            'code': code,
            'year': courseDoc.exists ? (courseDoc.data()?['year']?.toString() ?? 'N/A') : 'Year N/A',
          });
        }

        setState(() {
          assignedCourses = temp;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching courses: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: tealPrimary)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBox(),
          const SizedBox(height: 24),
          const Text('SESSION TYPE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tealDark)),
          const SizedBox(height: 10),
          _buildSessionTypeSelector(),
          const SizedBox(height: 24),
          const Text('SELECT COURSE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tealDark)),
          const SizedBox(height: 10),
          assignedCourses.isEmpty
              ? const Center(child: Text("No courses assigned to your UID."))
              : _buildCourseGrid(),
          const SizedBox(height: 28),
          _buildProceedButton(),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: tealPrimary.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text('Select course and session type to start taking attendance.',
          style: TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Wrap(
      spacing: 10,
      children: sessionTypes.map((type) {
        final isSelected = selectedSessionType == type;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (val) => setState(() => selectedSessionType = val ? type : null),
          selectedColor: tealPrimary,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        );
      }).toList(),
    );
  }

  Widget _buildCourseGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.5,
      ),
      itemCount: assignedCourses.length,
      itemBuilder: (context, index) {
        final course = assignedCourses[index];
        final isSelected = selectedCourse == course['code'];
        return GestureDetector(
          onTap: () => setState(() => selectedCourse = course['code']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? tealPrimary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? tealPrimary : Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(course['code']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(course['year']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: tealPrimary, foregroundColor: Colors.white),
        onPressed: (selectedCourse == null || selectedSessionType == null) ? null : () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AttendancePage(
            courseCode: selectedCourse!,
            sessionType: selectedSessionType!,
          )));
        },
        child: const Text('Proceed to Scanner'),
      ),
    );
  }
}