import 'package:flutter/material.dart';

class AdminHistoryLogScreen extends StatelessWidget {
  const AdminHistoryLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(title: const Text('History Log Alat'), backgroundColor: const Color(0xFF388E3C)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Timeline ON/OFF Semua Alat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                title: const Text('Exhaust Fan ON'),
                subtitle: const Text('16 Mar 2026, 10:30 - Gas: 520 ppm'),
                trailing: const Text('15 menit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
