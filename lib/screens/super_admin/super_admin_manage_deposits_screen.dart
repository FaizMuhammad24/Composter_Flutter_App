import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/compost_model.dart';
import '../../services/compost/compost_service.dart';
import '../../services/user/points_service.dart';
import '../../services/notifications/user_notification_service.dart';

class SuperAdminManageDepositsScreen extends StatefulWidget {
  const SuperAdminManageDepositsScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminManageDepositsScreen> createState() => _SuperAdminManageDepositsScreenState();
}

class _SuperAdminManageDepositsScreenState extends State<SuperAdminManageDepositsScreen> {
  bool _isLoading = true;
  List<CompostModel> _composts = [];
  String _filterStatus = 'pending'; // 'pending', 'approved', 'rejected', 'all'

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    setState(() => _isLoading = true);
    try {
      final all = await CompostService.getAllComposts();
      setState(() {
        _composts = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<CompostModel> get _filteredComposts {
    if (_filterStatus == 'all') return _composts;
    return _composts.where((c) => c.status == _filterStatus).toList();
  }

  Future<void> _approveDeposit(CompostModel deposit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi ACC', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('Setujui setoran dari ${deposit.userEmail} sebesar ${deposit.weight} kg? (+${deposit.points} Poin)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Setujui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await CompostService.updateCompostStatus(deposit.id, 'approved');
        await PointsService.addUserPoints(userEmail: deposit.userEmail, pointsToAdd: deposit.points);
        await UserNotificationService.notifyDepositApproved(
          deposit.userEmail, deposit.weight, deposit.points,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran berhasil disetujui!'), backgroundColor: Colors.green),
        );
        _loadDeposits();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyetujui setoran')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectDeposit(CompostModel deposit) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tolak Setoran', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak setoran dari ${deposit.userEmail} (${deposit.weight} kg)?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan (opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await CompostService.updateCompostStatus(deposit.id, 'rejected');
        await UserNotificationService.notifyDepositRejected(
          deposit.userEmail, deposit.weight, reason: reasonCtrl.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran ditolak & notifikasi dikirim ke user'), backgroundColor: Colors.orange),
        );
        _loadDeposits();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menolak setoran')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.superAdminPrimary));

    return Column(
      children: [
        // Filter chips
        Container(
          color: AppColors.superAdminBg,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Pending', 'pending', Colors.orange),
                const SizedBox(width: 8),
                _filterChip('Disetujui', 'approved', Colors.green),
                const SizedBox(width: 8),
                _filterChip('Ditolak', 'rejected', Colors.red),
                const SizedBox(width: 8),
                _filterChip('Semua', 'all', Colors.grey),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDeposits,
            color: AppColors.superAdminPrimary,
            child: _filteredComposts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'pending' ? 'Tidak ada setoran tertunda' : 'Tidak ada data',
                          style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredComposts.length,
                    itemBuilder: (context, index) {
                      final deposit = _filteredComposts[index];
                      return _buildDepositCard(deposit);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildDepositCard(CompostModel deposit) {
    Color statusColor;
    String statusLabel;
    switch (deposit.status) {
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'DISETUJUI';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'DITOLAK';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'PENDING';
    }

    final shortId = deposit.id.length >= 8 ? deposit.id.substring(0, 8).toUpperCase() : deposit.id.toUpperCase();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deposit.userEmail, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      Text('ID: $shortId', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _infoItem(Icons.monitor_weight_outlined, '${deposit.weight} kg'),
                const SizedBox(width: 24),
                _infoItem(Icons.stars_rounded, '${deposit.points} Pts', color: Colors.orange),
              ],
            ),
            if (deposit.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectDeposit(deposit),
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
                      onPressed: () => _approveDeposit(deposit),
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
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text, {Color color = Colors.black87}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins')),
      ],
    );
  }
}
