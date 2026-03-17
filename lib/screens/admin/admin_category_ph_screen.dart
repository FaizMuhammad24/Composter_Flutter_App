import 'package:flutter/material.dart';

class AdminCategoryPhScreen extends StatelessWidget {
  const AdminCategoryPhScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(title: const Text('Monitoring pH'), backgroundColor: const Color(0xFF9C27B0)),
      body: const Center(child: Text('pH Screen (Template sama seperti Temperature)', style: TextStyle(fontSize: 18))),
    );
  }
}
