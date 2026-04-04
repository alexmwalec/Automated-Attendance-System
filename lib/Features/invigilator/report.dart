import 'package:automated_attendance_system/Features/invigilator/invigilator_dashboard.dart';
import 'package:flutter/material.dart';


class Report extends StatelessWidget {
  const Report({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D00D2), // Purple colour

        title: const Text(
          "AAS", style: TextStyle(color: Colors.white),),
        leading: Builder(
          builder: (context) =>
              IconButton(icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),),),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text("Report page"),
      ),
    );
  }
}