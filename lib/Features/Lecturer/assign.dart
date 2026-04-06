import 'package:flutter/material.dart';

class Assign extends StatefulWidget {
  const Assign({super.key});

  @override
  State<Assign> createState() => _AssignState();
}

class _AssignState extends State<Assign> {
  static const Color unimaPurple = Color(0xFF5D00D2);
  static const Color unimaGold = Color(0xFFC5A021);
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E9EF), // Light blue background
      appBar: AppBar(
        backgroundColor: unimaPurple,
        title: const Text("AAS",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSidebarVisible = !_isSidebarVisible;
            });
          },
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
      body: Row(
        children: [
          // Sidebar
          if (_isSidebarVisible)
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(
                      color: Colors.blue.shade100.withOpacity(0.5), width: 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          size: 100, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'MAIN NAVIGATION MENU',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildSidebarItem(context, Icons.stars_outlined,
                            'Dashboard', '/dashboard'),
                        _buildSidebarItem(context, Icons.person_outline,
                            'Profile', '/profile'),
                        _buildExpandableSidebarItem(
                            context, Icons.edit_note, 'Take Attendance', [
                          {'title': 'Exam Attendance', 'route': '/scanner'},
                          {'title': 'Class Attendance', 'route': '/scanner'},
                          {'title': 'Lab Attendance', 'route': '/scanner'},
                        ]),
                        _buildSidebarItem(
                            context,
                            Icons.assignment_turned_in_outlined,
                            'Assign Invigilator',
                            '#',
                            isSelected: true),
                        _buildSidebarItem(context, Icons.analytics_outlined,
                            'Analytics', '#'),
                        _buildSidebarItem(context, Icons.history,
                            'Attendance History', '/attendance_history'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Write Report
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: unimaGold.withOpacity(0.6),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_note, size: 30, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Write Report',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Exam Details Row
                  Container(
                    color: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
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
                        hintText: "Enter report or assignment details here...",
                        contentPadding: EdgeInsets.all(10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Instruction Text
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          color: Colors.black, fontSize: 13, height: 1.4),
                      children: [
                        TextSpan(
                            text:
                            "Before confirming, ensure that the exam details are correct, the invigilator is available at the selected time, the venue is correct, and no scheduling conflict exists. Submit the form only after verifying all information. "),
                        TextSpan(
                          text:
                          "Assign the Invigilator only after verifying all information",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                          "Assign", const Color(0xFF1A237E), () {}),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods for Navigation
  Widget _buildSidebarItem(
      BuildContext context, IconData icon, String title, String route,
      {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? unimaPurple : Colors.black54),
      title: Text(title,
          style: TextStyle(
              color: isSelected ? unimaPurple : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        if (route != '#' && route != ModalRoute.of(context)?.settings.name) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildExpandableSidebarItem(BuildContext context, IconData icon,
      String title, List<Map<String, String>> subItems) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      children: subItems.map((item) {
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 70),
          title: Text(item['title']!, style: const TextStyle(fontSize: 13)),
          onTap: () => Navigator.pushReplacementNamed(context, item['route']!),
        );
      }).toList(),
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

  Widget _buildActionButton(
      String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 100,
      height: 35,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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