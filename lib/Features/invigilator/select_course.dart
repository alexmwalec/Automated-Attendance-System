import 'package:flutter/material.dart';

class Course extends StatelessWidget {
  const Course({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Course"),
      ),
      body: const Center(
        child: Text(
          "Course Selection",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}