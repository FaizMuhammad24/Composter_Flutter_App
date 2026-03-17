import 'package:flutter/material.dart';
import 'user_redeem_screen.dart';

class UserRewardsScreen extends StatelessWidget {
  const UserRewardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(title: const Text('Katalog Reward'), backgroundColor: const Color(0xFF1976D2)),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildRewardCard(context, 'Voucher Alfamart 50k', 500),
          _buildRewardCard(context, 'Pupuk Organik 5kg', 300),
          _buildRewardCard(context, 'Bibit Tanaman', 200),
          _buildRewardCard(context, 'Tas Belanja', 150),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, String name, int points) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserRedeemScreen(rewardName: name, points: points))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.card_giftcard, size: 60, color: Colors.orange),
              const SizedBox(height: 8),
              Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$points poin', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
