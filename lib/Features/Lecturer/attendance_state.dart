import 'package:flutter/foundation.dart';

String normalizeReg(String reg) =>
    reg.replaceAll('/', '-').trim().toLowerCase();

class AttendanceState {
  static final ValueNotifier<List<Map<String, String>>> markedStudents =
      ValueNotifier([]);

  static void addStudent(Map<String, String> student) {
    final normalized = {
      'regNo': normalizeReg(student['regNo']!),
      'name': student['name']!,
      'surname': student['surname']!,
    };
    final current = List<Map<String, String>>.from(markedStudents.value);
    final alreadyExists = current.any(
      (e) => normalizeReg(e['regNo']!) == normalized['regNo'],
    );
    if (!alreadyExists) {
      current.insert(0, normalized);
      markedStudents.value = current;
    }
  }

  static bool isMarked(String regNo) {
    return markedStudents.value.any(
      (e) => normalizeReg(e['regNo']!) == normalizeReg(regNo),
    );
  }

  static void clear() {
    markedStudents.value = [];
  }
}
