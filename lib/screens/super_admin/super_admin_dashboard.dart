import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/rewards/reward_service.dart';
import '../../services/admin/admin_service.dart';
import '../../services/user/user_service.dart';
import '../../services/compost/compost_service.dart';
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
  int _totalAdmins = 0;
  int _totalUsers = 0;
  int _totalRewards = 0;
  int _pendingDeposits = 0;
  int _totalPoints = 0;
  List<Map<String, dynamic>> _recentActivities = [];

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

    try {
      final results = await Future.wait([
        AdminService.getAllAdmins(),
        UserService.getAllUsers(),
        RewardService.getAllRewards(),
        CompostService.getAllComposts(),
        RewardService.getTotalPointsValue(),
      ]);

      final adminsList = results[0] as List;
      final usersList = results[1] as List;
      final rewardsList = results[2] as List;
      final allComposts = results[3] as List;
      final totalPoints = (results[4] as int);

      // Build recent activities from composts (last 5)
      final activities = <Map<String, dynamic>>[];
      
      // Add last 5 composts as activities
      final recentComposts = allComposts
          .take(5)
          .map((c) {
            final compost = c as dynamic;
            return {
              'icon': Icons.recycling,
              'color': Colors.green,
              'title': 'Setoran Baru Diterima',
              'desc': '${compost.weight} kg dari ${compost.userEmail.split('@')[0]}',
              'time': _formatTime(compost.createdAt),
            };
          })
          .toList();
      activities.addAll(recentComposts);
      
      // Add recent reward claims as activities  
      try {
        final claims = await RewardService.getPendingClaims();
        for (final claim in claims.take(3)) {
          activities.add({
            'icon': Icons.card_giftcard,
            'color': Colors.orange,
            'title': 'Klaim Hadiah',
            'desc': '${claim['rewardName']} oleh ${(claim['userEmail'] as String).split('@')[0]}',
            'time': _formatTime(claim['createdAt']),
          });
        }
      } catch (_) {}

      activities.sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));

      if (mounted) {
        setState(() {
          _totalAdmins = adminsList.length;
          _totalUsers = usersList.length;
          _totalRewards = rewardsList.length;
          _pendingDeposits = allComposts.where((c) => (c as dynamic).status == 'pending').length;
          _totalPoints = totalPoints;
          _recentActivities = activities.take(5).toList();
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading SA dashboard stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(dynamic rawTime) {
    try {
      final dt = rawTime is String ? DateTime.parse(rawTime) : (rawTime as DateTime);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return '';
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
              Expanded(child: LoadingShimmer(width: 100, height: 120, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 8),
              Expanded(child: LoadingShimmer(width: 100, height: 120, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 8),
              Expanded(child: LoadingShimmer(width: 100, height: 120, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 8),
              Expanded(child: LoadingShimmer(width: 100, height: 120, borderRadius: BorderRadius.circular(16))),
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
              child: Icon(Icons.eco, size: 40, color: Colors.white),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Full Access',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      ),
                    ],
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
        Expanded(child: _buildStatCard('Total Admin', '$_totalAdmins', Icons.shield_outlined, const Color(0xFFEF5350), 2)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Total User', '$_totalUsers', Icons.people_outlined, const Color(0xFF42A5F5), 2)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Total Hadiah', '$_totalRewards', Icons.card_giftcard_outlined, const Color(0xFF66BB6A), 1)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Setoran\nPending', '$_pendingDeposits', Icons.inbox_outlined, const Color(0xFFFF9800), 2)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, int navIndex) {
    return GestureDetector(
      onTap: () => widget.onNavigate(navIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins'),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    if (_recentActivities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Center(
          child: Text('Belum ada aktivitas terbaru', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentActivities.length,
      itemBuilder: (context, index) {
        final act = _recentActivities[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (act['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(act['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(act['desc'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins')),
                  ],
                ),
              ),
              Text(
                act['time'] as String,
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Poppins', fontWeight: FontWeight.bold),
              ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
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
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
