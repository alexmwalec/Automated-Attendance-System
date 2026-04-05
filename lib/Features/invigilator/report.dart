import 'package:automated_attendance_system/Features/invigilator/invigilator_dashboard.dart';
import 'package:flutter/material.dart';


class Report extends StatelessWidget {
  const Report({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F9CBA), // Background colour shade blue blue[200}
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D00D2), // Purple colour

        title: const Text(
          "AAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold )),
        leading: Builder(
          builder: (context) =>
              IconButton(icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications_none,color:Colors.white), onPressed: (){},),
          const Padding(padding: EdgeInsets.only(right:16 ),
          child: CircleAvatar(
              backgroundColor: Colors.grey,
             radius: 15, ) )
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(
            width:double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A021),
              border: Border.all(color: Colors.grey.shade400),
            ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text('Write Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.white)),
            const SizedBox( height: 16,)
            ]
    ),
    )
          ]
      ),
      )
    );
  }
}