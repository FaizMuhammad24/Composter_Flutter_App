import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/rewards/reward_service.dart';
import '../../widgets/common/loading_shimmer.dart';

class SuperAdminDashboard extends StatefulWidget {
  final Function(int) onNavigate;
  const SuperAdminDashboard({Key? key, required this.onNavigate}) : super(key: key);

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final int _totalAdmins = 1;
  final int _totalUsers = 3;
  int _totalRewards = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
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
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    _animationController.reset();
    await Future.delayed(const Duration(milliseconds: 800));
    final rewardsCount = await RewardService.getTotalRewards();
    final pointsSum = await RewardService.getTotalPointsValue();

    if (mounted) {
      setState(() {
        _totalRewards = rewardsCount;
        _totalPoints = pointsSum;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.superAdminPrimary,
      child: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingShimmer(width: double.infinity, height: 120, borderRadius: BorderRadius.circular(24)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: LoadingShimmer(width: 100, height: 140, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 10),
              Expanded(child: LoadingShimmer(width: 100, height: 140, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 10),
              Expanded(child: LoadingShimmer(width: 100, height: 140, borderRadius: BorderRadius.circular(16))),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildSectionTitle('Aktivitas Sistem Terbaru'),
              const SizedBox(height: 12),
              _buildRecentActivityList(),
              const SizedBox(height: 24),
              _buildSectionTitle('Ringkasan Sistem'),
              const SizedBox(height: 12),
              _buildSystemSummaryCard(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC62828), Color(0xFFB71C1C)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.superAdminPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang!',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Poppins'),
                ),
                const Text(
                  'Super Admin',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🛡️ Full Access',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Admin', '$_totalAdmins', Icons.shield_outlined, const Color(0xFFEF5350))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Total User', '$_totalUsers', Icons.people_outlined, const Color(0xFF42A5F5))),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Total Hadiah', '$_totalRewards', Icons.card_giftcard_outlined, const Color(0xFF66BB6A))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins'),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.superAdminPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    final activities = [
      {'title': 'Suhu Mesin A Kritis', 'time': '10 mnt lalu', 'type': 'alert', 'desc': 'Melewati batas 65°C'},
      {'title': 'User Budi Mendaftar', 'time': '1 jam lalu', 'type': 'user', 'desc': 'Akun baru dibuat'},
      {'title': 'Reward Diklaim', 'time': '3 jam lalu', 'type': 'reward', 'desc': 'Pupuk Kompos 5kg oleh Ani'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final act = activities[index];
        IconData icon;
        Color color;

        if (act['type'] == 'alert') {
          icon = Icons.warning_amber_rounded;
          color = Colors.orange;
        } else if (act['type'] == 'user') {
          icon = Icons.person_add_alt_1_rounded;
          color = Colors.blue;
        } else {
          icon = Icons.card_giftcard_rounded;
          color = Colors.green;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(act['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(act['desc']!, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins')),
                  ],
                ),
              ),
              Text(act['time']!, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemSummaryCard() {
    final categories = RewardService.getCategories();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Total Poin Reward', '$_totalPoints poin', Icons.stars_rounded, Colors.amber),
          const Divider(height: 24, color: Colors.black12),
          _buildSummaryRow('Kategori Reward', categories.join(', '), Icons.category_outlined, Colors.purple),
          const Divider(height: 24, color: Colors.black12),
          _buildSummaryRow('Status Sistem', '● Online', Icons.circle, Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins')),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            ],
          ),
        ),
      ],
    );
  }
}


