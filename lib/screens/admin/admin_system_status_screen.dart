import 'package:flutter/material.dart';

class AdminSystemStatusScreen extends StatelessWidget {
  const AdminSystemStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('System Status'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Koneksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatusCard('WiFi ESP32', true, 'Connected'),
            _buildStatusCard('Firebase', true, 'Online'),
            const SizedBox(height: 24),
            const Text('Status Sensor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatusCard('Sensor Suhu', true, 'Online'),
            _buildStatusCard('Sensor Kelembaban', true, 'Online'),
            _buildStatusCard('Sensor pH', true, 'Online'),
            _buildStatusCard('Sensor Gas', true, 'Online'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, bool isOnline, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOnline ? Colors.green : Colors.red,
          child: Icon(
            isOnline ? Icons.check : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Last update: 2 seconds ago'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
