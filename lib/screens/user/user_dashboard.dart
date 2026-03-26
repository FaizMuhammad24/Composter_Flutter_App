import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/history/history_service.dart';
import 'user_deposit_screen.dart';
import 'user_deposit_history_screen.dart';
import 'user_rewards_screen.dart';
import 'widgets/user_header.dart';
import '../../services/user/user_service.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../services/rewards/reward_service.dart';
import '../../models/reward_model.dart';

class UserDashboard extends StatefulWidget {
  final UserModel user;

  const UserDashboard({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double _totalWeight = 0.0;
  int _totalExchanged = 0;
  late UserModel _currentUser;
  List<RewardModel> _popularRewards = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _animationController.reset();
    
    try {
      // 0. Seed data if needed
      await RewardService.seedInitialData();

      // 1. Reload user data for points
      final freshUser = await UserService.getUserByEmail(_currentUser.email);
      if (freshUser != null && mounted) {
        setState(() => _currentUser = freshUser);
      }

      // 2. Reload history for total weight
      final history = await HistoryService.getUserHistory(_currentUser.email);
      double weightSum = 0;
      for (var item in history) {
        weightSum += item.weight;
      }

      // 3. Load Popular Rewards
      final rewards = await RewardService.getPopularRewards();

      if (mounted) {
        setState(() {
          _totalWeight = weightSum;
          _popularRewards = rewards;
        });
      }
    } catch(e) {
      // Ignore errors for now
      print('Dashboard load error: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserHeader(userEmail: _currentUser.email),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFF5F5DC)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF2D5016),
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingShimmer(width: double.infinity, height: 260, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 24),
          LoadingShimmer(width: 150, height: 24, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: LoadingShimmer(width: 100, height: 100, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 16),
              Expanded(child: LoadingShimmer(width: 100, height: 100, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 16),
              Expanded(child: LoadingShimmer(width: 100, height: 100, borderRadius: BorderRadius.circular(16))),
            ],
          ),
          const SizedBox(height: 24),
          const ListItemShimmer(),
          const ListItemShimmer(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildPopularRewards(),
            const SizedBox(height: 24),
            _buildKomposTips(),
            const SizedBox(height: 120),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.38).clamp(260.0, 310.0);
    
    return Container(
      height: cardHeight,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D5016), Color(0xFF6B8E23)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Icon(
              Icons.local_florist,
              size: 70,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 90,
            right: 32,
            child: Icon(
              Icons.spa,
              size: 40,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            top: 24,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hai, Selamat Datang!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  _currentUser.name,
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik Keseluruhan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildHeroStatCard(Icons.delete_outline, '${_totalWeight.toStringAsFixed(1).replaceAll('.0', '')} kg', 'Disetor'),
                    const SizedBox(width: 10),
                    _buildHeroStatCard(Icons.star_outline, '${_currentUser.points ?? 0}', 'Poin'),
                    const SizedBox(width: 10),
                    _buildHeroStatCard(Icons.card_giftcard, '${_totalExchanged}x', 'Ditukar'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 2. QUICK ACTION ==========
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Color(0xFF2D5016), size: 22),
              const SizedBox(width: 6),
              const Text(
                'Quick Action',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                icon: Icons.delete_sweep,
                label: 'Setor\nSampah',
                color: const Color(0xFF4CAF50),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDepositScreen(userEmail: _currentUser.email),
                    ),
                  );
                  _loadData(); // REFRESH AFTER RETURN
                },
              ),
              _buildActionButton(
                icon: Icons.history,
                label: 'Riwayat Setor Sampah',
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDepositHistoryScreen(userEmail: _currentUser.email),
                  ),
                ),
              ),
              _buildActionButton(
                icon: Icons.redeem,
                label: 'Tukar\nPoin',
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserRewardsScreen(user: _currentUser)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(icon, size: 30, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== 4. REWARD TERPOPULER ==========
  Widget _buildPopularRewards() {
    if (_popularRewards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Belum ada reward populer', style: TextStyle(fontFamily: 'Poppins'))),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.redeem, color: Color(0xFF2D5016)),
                  SizedBox(width: 8),
                  Text(
                    'Reward Terpopuler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5016),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserRewardsScreen(user: _currentUser)),
                ),
                child: const Text(
                  'Lihat Semua →',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _popularRewards.length,
            itemBuilder: (context, index) {
              final reward = _popularRewards[index];
              return _buildRewardCard(
                name: reward.name,
                points: reward.points.toString(),
                stars: 5,
                imageUrl: reward.imageUrl,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard({
    required String name,
    required String points,
    required int stars,
    required String imageUrl,
  }) {
    final colors = [Colors.orange, Colors.blue, Colors.green, Colors.purple];
    final MaterialColor color = colors[name.length % colors.length];

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(Icons.card_giftcard, size: 50, color: color),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$points pts',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 13,
                      color: i < stars ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    // ========== 3. TIPS KOMPOS ==========
  Widget _buildKomposTips() {
    final tips = [
      {
        'icon': Icons.eco,
        'title': 'Campur Hijau & Coklat',
        'desc': 'Padukan sampah hijau (sisa makanan) dan coklat (daun kering).',
        'color': const Color(0xFF4CAF50),
      },
      {
        'icon': Icons.water_drop,
        'title': 'Jaga Kelembaban',
        'desc': 'Pastikan kompos lembab seperti spons basah, tidak terlalu kering atau becek.',
        'color': const Color(0xFF2196F3),
      },
      {
        'icon': Icons.sync,
        'title': 'Aduk Rutin',
        'desc': 'Aduk tumpukan kompos setiap 2-3x/hari agar oksigen merata',
        'color': const Color(0xFFFF9800),
      },
      {
        'icon': Icons.thermostat,
        'title': 'Suhu Ideal',
        'desc': 'Kompos aktif bisa mencapai 55–65°C — itu tanda fermentasi berhasil!',
        'color': const Color(0xFFE91E63),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
               Icon(Icons.lightbulb_outline, color: Color(0xFF2D5016)),
               SizedBox(width: 8),
               Text(
                'Tips Kompos Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              final color = tip['color'] as Color;
              return Container(
                width: 195,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            tip['icon'] as IconData,
                            size: 18,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tip['desc'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }



}
