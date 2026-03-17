import 'package:flutter/material.dart';

class AdminCategoryGasScreen extends StatelessWidget {
  const AdminCategoryGasScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(title: const Text('Monitoring Gas (MQ-4)'), backgroundColor: const Color(0xFFE53935)),
      body: const Center(child: Text('Gas Screen (Template sama seperti Temperature)', style: TextStyle(fontSize: 18))),
    );
  }
}
