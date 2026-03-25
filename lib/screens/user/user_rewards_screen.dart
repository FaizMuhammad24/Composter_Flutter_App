import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'user_redeem_screen.dart';
import '../../models/user_model.dart';
import '../../models/reward_model.dart';
import '../../services/rewards/reward_service.dart';

class UserRewardsScreen extends StatefulWidget {
  final UserModel user;
  const UserRewardsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserRewardsScreen> createState() => _UserRewardsScreenState();
}

class _UserRewardsScreenState extends State<UserRewardsScreen> {
  List<RewardModel> _rewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rewards = await RewardService.getAllRewards();
    if (mounted) {
      setState(() {
        _rewards = rewards;
        _isLoading = false;
      });
    }
  }

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
            child: Column(
              children: [
                const Text(
                  'Saldo Poin Saat Ini',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.user.points ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Pts',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _rewards.isEmpty 
                    ? const Center(child: Text('Belum ada reward', style: TextStyle(fontFamily: 'Poppins')))
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _rewards.length,
                        itemBuilder: (context, index) {
                          final reward = _rewards[index];
                          // Determine icon/color loosely based on category
                          IconData icon = Icons.card_giftcard;
                          Color color = Colors.orange;
                          
                          if (reward.category.toLowerCase() == 'voucher') {
                            icon = Icons.confirmation_number;
                            color = Colors.blue;
                          } else if (reward.category.toLowerCase() == 'produk') {
                            icon = Icons.grass;
                            color = Colors.green;
                          } else if (reward.category.toLowerCase() == 'merchandise') {
                            icon = Icons.shopping_bag;
                            color = Colors.purple;
                          }
                          
                          return _buildRewardCard(
                            context,
                            name: reward.name,
                            points: reward.points,
                            icon: icon,
                            color: color,
                          );
                        },
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
              MaterialPageRoute(builder: (_) => UserRedeemScreen(userEmail: widget.user.email, rewardName: name, pointsPerItem: points, icon: icon, color: color))
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
