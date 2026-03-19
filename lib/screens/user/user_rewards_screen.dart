import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'user_redeem_screen.dart';

class UserRewardsScreen extends StatelessWidget {
  const UserRewardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar abu-abu terang
      appBar: AppBar(
        title: const Text(
          'Katalog Reward',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          // Banner Poin
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'Saldo Poin Saat Ini',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 13),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: 32),
                    SizedBox(width: 8),
                    Text(
                      '2.450',
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Pts',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Agar kartu terlihat proporsional (tinggi > lebar)
              children: [
                _buildRewardCard(
                  context, 
                  name: 'Voucher Alfamart 50k', 
                  points: 500, 
                  icon: Icons.confirmation_number, 
                  color: Colors.blue
                ),
                _buildRewardCard(
                  context, 
                  name: 'Pupuk Kompos 5kg', 
                  points: 300, 
                  icon: Icons.grass, 
                  color: Colors.green
                ),
                _buildRewardCard(
                  context, 
                  name: 'Bibit Tanaman', 
                  points: 200, 
                  icon: Icons.local_florist, 
                  color: Colors.teal
                ),
                _buildRewardCard(
                  context, 
                  name: 'Tas Belanja Ramah Lingkungan', 
                  points: 150, 
                  icon: Icons.shopping_bag, 
                  color: Colors.orange
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, {required String name, required int points, required IconData icon, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => UserRedeemScreen(rewardName: name, pointsPerItem: points, icon: icon, color: color))
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Text(
                    name, 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins', height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$points Pts', 
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
