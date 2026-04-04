import 'package:flutter/material.dart';

class Report extends StatelessWidget {
  const Report({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Write Report"),
      ),
      body: const Center(
        child: Text(
          "Report Screen",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}