import 'package:flutter/material.dart';

class UserHistoryScreen extends StatelessWidget {
  const UserHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(title: const Text('Riwayat Penyetoran'), backgroundColor: const Color(0xFF1976D2)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.delete, color: Colors.white)),
              title: const Text('Organik Basah - 5 kg'),
              subtitle: const Text('15 Mar 2026, 14:30'),
              trailing: const Text('+50 poin', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
