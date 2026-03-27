import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/history/history_service.dart';
import '../../services/user/user_service.dart';
import '../../services/rewards/reward_service.dart';
import '../../models/compost_model.dart';
import 'package:intl/intl.dart';

class UserHistoryScreen extends StatefulWidget {
  final UserModel user;
  const UserHistoryScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  bool _isLoading = true;
  List<CompostModel> _recentTransactions = [];
  List<Map<String, dynamic>> _recentClaims = [];
  double _totalWeight = 0;
  int _rewardExchangeCount = 0;
  int _currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch fresh user data from Firestore (same as dashboard)
      final freshUser = await UserService.getUserByEmail(widget.user.email);

      // 2. Fetch transaction history
      final history = await HistoryService.getUserHistory(widget.user.email);
      double weightSum = 0;
      int approvedCount = 0;
      for (var item in history) {
        weightSum += item.weight;
        if (item.status == 'approved') approvedCount++;
      }

      // 3. Fetch reward claims
      final claims = await RewardService.getUserClaims(widget.user.email);

      if (mounted) {
        setState(() {
          _currentPoints = freshUser?.points ?? widget.user.points ?? 0;
          _recentTransactions = history.take(20).toList();
          _recentClaims = claims.take(20).toList();
          _totalWeight = weightSum;
          _rewardExchangeCount = approvedCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Riwayat',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins')),
          backgroundColor: AppColors.primary,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          color: AppColors.primary,
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: Colors.white,
            backgroundColor: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Poin Anda',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'Poppins')),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentPoints Pts',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildStatCard(
                                value: '${_totalWeight.toStringAsFixed(1)} kg',
                                label: 'Total Setor',
                                color: const Color(0xFF81D4FA)),
                            const SizedBox(width: 16),
                            _buildStatCard(
                                value: '${_rewardExchangeCount}x',
                                label: 'Reward Ditukar',
                                color: const Color(0xFFFFB74D)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                          child: Text('Riwayat Transaksi',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins')),
                        ),
                        TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppColors.primary,
                          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                          tabs: const [
                            Tab(text: 'Setor Sampah'),
                            Tab(text: 'Tukar Poin'),
                          ],
                        ),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : TabBarView(
                                  children: [
                                    _buildDepositList(),
                                    _buildClaimsList(),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepositList() {
    if (_recentTransactions.isEmpty) {
      return const Center(child: Text('Belum ada riwayat setoran.', style: TextStyle(fontFamily: 'Poppins')));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final tx = _recentTransactions[index];
        final isApproved = tx.status == 'approved';
        return _buildTransactionItem(
          icon: Icons.recycling,
          iconColor: AppColors.primary,
          title: 'Setor Sampah',
          subtitle: DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tx.createdAt)),
          mainValueText: '${tx.weight.toStringAsFixed(1)} Kg',
          pointsText: isApproved ? '+${tx.points} Pts' : null,
          status: tx.status,
          pointsLabel: 'poin ditambahkan',
        );
      },
    );
  }

  Widget _buildClaimsList() {
    if (_recentClaims.isEmpty) {
      return const Center(child: Text('Belum ada riwayat tukar poin.', style: TextStyle(fontFamily: 'Poppins')));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _recentClaims.length,
      itemBuilder: (context, index) {
        final claim = _recentClaims[index];
        final isApproved = claim['status'] == 'approved';
        return _buildTransactionItem(
          icon: Icons.card_giftcard,
          iconColor: Colors.orange,
          title: 'Klaim: ${claim['rewardName']}',
          subtitle: DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(claim['createdAt'])),
          mainValueText: '${claim['totalPoints']} Pts',
          pointsText: isApproved ? null : 'Menunggu Admin',
          status: claim['status'],
          pointsLabel: '',
        );
      },
    );
  }

  Widget _buildStatCard(
      {required String value, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String mainValueText,
    String? pointsText,
    required String status,
    required String pointsLabel,
  }) {
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'Disetujui';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'Ditolak';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Menunggu';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Poppins'))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(statusLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontFamily: 'Poppins')),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Row(children: [
                  Text(mainValueText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                          fontFamily: 'Poppins')),
                  if (pointsText != null) ...[
                    const SizedBox(width: 12),
                    if (pointsLabel.isNotEmpty) ...[
                      Text(pointsLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontFamily: 'Poppins')),
                      const SizedBox(width: 6),
                    ],
                    Text(pointsText,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.orange,
                            fontFamily: 'Poppins')),
                  ],
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
