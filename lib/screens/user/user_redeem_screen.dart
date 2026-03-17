import 'package:flutter/material.dart';

class UserRedeemScreen extends StatelessWidget {
  final String rewardName;
  final int points;

  const UserRedeemScreen({Key? key, required this.rewardName, required this.points}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(title: const Text('Tukar Poin'), backgroundColor: const Color(0xFF1976D2)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.card_giftcard, size: 100, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(rewardName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$points poin', style: const TextStyle(fontSize: 18, color: Colors.orange)),
                    const SizedBox(height: 16),
                    const Text('Poin Anda: 450', style: TextStyle(fontSize: 16)),
                    Text('Sisa poin: ${450 - points}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Penukaran berhasil!'), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Konfirmasi Tukar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
