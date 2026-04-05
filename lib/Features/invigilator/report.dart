import 'package:automated_attendance_system/Features/invigilator/invigilator_dashboard.dart';
import 'package:flutter/material.dart';

class Report extends StatelessWidget {
  const Report({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E9EF), // Light blue background from image
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D00D2), // Purple colour
        title: const Text("AAS",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 15,
            ),
          )
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Write Report
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC5A021).withOpacity(0.6), // Gold/Mustard color
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: const [
                  Icon(Icons.edit_note, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Write Report',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Exam Details Table-like Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailColumn("COURSE", "COM 412"),
                  _buildDetailColumn("DATE", "16 March, 2026"),
                  _buildDetailColumn("TIME", "18:30 PM"),
                  _buildDetailColumn("ROOM", "CK 2"),
                  _buildDetailColumn("INVIGILATOR", "Paul Mwale"),
                ],
              ),
            ),
            const SizedBox(height: 1),

            // Text Input Area
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const TextField(
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Write report here",
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Instruction Text
            RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(
                      text:
                      "Before submitting, ensure all exam details are correct and clearly described any incident, observations, or issues that occurred during the session. "),
                  TextSpan(
                    text: "Submit the report only after verifying all information",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton("Clear", const Color(0xFF1A237E), () {}),
                const SizedBox(width: 40),
                _buildActionButton("Submit", const Color(0xFF1A237E), () {}),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 100,
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}