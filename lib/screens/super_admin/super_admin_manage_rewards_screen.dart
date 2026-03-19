import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/reward_model.dart';
import '../../services/reward_service.dart';
import 'super_admin_create_reward_screen.dart';

class ManageRewardsScreen extends StatefulWidget {
  const ManageRewardsScreen({Key? key}) : super(key: key);

  @override
  State<ManageRewardsScreen> createState() => _ManageRewardsScreenState();
}

class _ManageRewardsScreenState extends State<ManageRewardsScreen> {
  List<RewardModel> _rewards = [];
  List<RewardModel> _filtered = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _rewards = RewardService.getAllRewards();
        _filtered = _rewards;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filtered = query.isEmpty
          ? _rewards
          : RewardService.searchRewards(query);
    });
  }

  void _deleteReward(RewardModel reward) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Reward', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "${reward.name}"?', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () {
              RewardService.deleteReward(reward.id);
              Navigator.pop(context);
              _loadRewards();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${reward.name} berhasil dihapus'),
                  backgroundColor: Colors.red[400],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  void _navigateToCreate({RewardModel? existing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRewardScreen(existingReward: existing),
      ),
    );
    _loadRewards();
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'voucher': return const Color(0xFF42A5F5);
      case 'produk': return const Color(0xFF66BB6A);
      default: return const Color(0xFFFF7043);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.superAdminPrimary))
              : _filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadRewards,
                      color: AppColors.superAdminPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) => _buildRewardCard(_filtered[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.superAdminBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Stats Row
          Row(
            children: [
              _buildMiniStat('Total', '${_rewards.length}', Colors.red),
              const SizedBox(width: 8),
              _buildMiniStat('Poin Total', '${RewardService.getTotalPointsValue()}', Colors.amber[700]!),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToCreate(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.superAdminPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search Bar
          TextField(
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Cari reward...',
              hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins')),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildRewardCard(RewardModel reward) {
    final catColor = _categoryColor(reward.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            color: catColor.withOpacity(0.1),
            child: reward.imageUrl.isNotEmpty
                ? Image.network(
                    reward.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.card_giftcard, color: catColor, size: 28),
                  )
                : Icon(Icons.card_giftcard, color: catColor, size: 28),
          ),
        ),
        title: Text(reward.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(reward.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(reward.category, style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text('${reward.points} poin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
              onPressed: () => _navigateToCreate(existing: reward),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
              onPressed: () => _deleteReward(reward),
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_outlined, size: 80, color: Colors.red[100]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Tidak ditemukan "$_searchQuery"' : 'Belum ada reward',
            style: const TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Poppins'),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.superAdminPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Reward Pertama', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
