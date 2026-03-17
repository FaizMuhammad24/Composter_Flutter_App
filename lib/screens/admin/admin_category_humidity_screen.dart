import 'package:flutter/material.dart';

class AdminCategoryHumidityScreen extends StatelessWidget {
  const AdminCategoryHumidityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(title: const Text('Monitoring Kelembaban'), backgroundColor: const Color(0xFF2196F3)),
      body: const Center(child: Text('Kelembaban Screen (Template sama seperti Temperature)', style: TextStyle(fontSize: 18))),
    );
  }
}
