import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/rewards/reward_service.dart';
import '../../services/user/points_service.dart';
import '../../services/notifications/user_notification_service.dart';

class SuperAdminRewardClaimsScreen extends StatefulWidget {
  const SuperAdminRewardClaimsScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminRewardClaimsScreen> createState() => _SuperAdminRewardClaimsScreenState();
}

class _SuperAdminRewardClaimsScreenState extends State<SuperAdminRewardClaimsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _claims = [];

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    setState(() => _isLoading = true);
    try {
      final claims = await RewardService.getPendingClaims();
      if (mounted) setState(() { _claims = claims; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ACC Klaim Hadiah', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(
          'Setujui klaim ${claim["quantity"]}x "${claim["rewardName"]}"\noleh ${claim["userName"]}?\n\nPoin yang dipotong: ${claim["totalPoints"]} pts',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ACC', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        // 1. Update status klaim
        await RewardService.approveClaim(claim['id']);

        // 2. Potong poin user
        await PointsService.deductUserPoints(
          userEmail: claim['userEmail'],
          pointsToDeduct: claim['totalPoints'] as int,
        );

        // 3. Kirim notifikasi ke user
        await UserNotificationService.notifyRewardApproved(
          claim['userEmail'],
          claim['rewardName'],
          claim['quantity'] as int,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klaim disetujui & notifikasi dikirim ke user!'), backgroundColor: Colors.green),
        );
        _loadClaims();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tolak Klaim Hadiah', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(
          'Tolak klaim "${claim["rewardName"]}"\noleh ${claim["userName"]}?\n\nPoin ${claim["totalPoints"]} pts TIDAK akan dikurangi.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        // 1. Update status klaim (rejected — poin tidak perlu dikembalikan karena belum dipotong)
        await RewardService.rejectClaim(claim['id']);

        // 2. Kirim notifikasi ke user bahwa klaim ditolak (poin tidak berubah)
        await UserNotificationService.notifyRewardRejected(
          claim['userEmail'],
          claim['rewardName'],
          0, // tidak perlu refund karena poin belum dipotong
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Klaim ditolak & notifikasi dikirim ke user'), backgroundColor: Colors.orange),
        );
        _loadClaims();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.superAdminPrimary))
        : RefreshIndicator(
            onRefresh: _loadClaims,
            color: AppColors.superAdminPrimary,
            child: _claims.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.green[100]),
                        const SizedBox(height: 16),
                        const Text('Tidak ada klaim yang menunggu', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: _claims.length,
                    itemBuilder: (_, i) => _buildClaimCard(_claims[i]),
                  ),
          );
  }

  Widget _buildClaimCard(Map<String, dynamic> claim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.card_giftcard, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${claim["quantity"]}x ${claim["rewardName"]}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14),
                      ),
                      Text(
                        claim['userName'] ?? claim['userEmail'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${claim["totalPoints"]} pts',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Poin belum dipotong. Poin baru dikurangi setelah diklik ACC.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(claim),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Tolak', style: TextStyle(fontFamily: 'Poppins')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(claim),
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('ACC', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
