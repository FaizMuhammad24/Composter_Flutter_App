import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(title: const Text('Notifikasi'), backgroundColor: const Color(0xFF388E3C)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange, size: 40),
              title: const Text('Suhu Tinggi', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('10:30 - Suhu mencapai 62°C'),
              trailing: TextButton(onPressed: () {}, child: const Text('Mark Read')),
            ),
          ),
        ],
      ),
    );
  }
}
