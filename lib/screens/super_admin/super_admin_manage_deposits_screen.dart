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
  List<CompostModel> _pendingDeposits = [];

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
        _pendingDeposits = all.where((c) => c.status == 'pending').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveDeposit(CompostModel deposit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
        // 1. Update status in compost collection
        await CompostService.updateCompostStatus(deposit.id, 'approved');
        
        // 2. Add points to user
        await PointsService.addUserPoints(userEmail: deposit.userEmail, pointsToAdd: deposit.points);
        
        // 3. Notify User
        await UserNotificationService.notifyDepositApproved(
          deposit.userEmail, 
          deposit.weight, 
          deposit.points,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran berhasil disetujui!'), backgroundColor: Colors.green),
        );
        _loadDeposits();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyetujui setoran')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.superAdminPrimary));

    if (_pendingDeposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Tidak ada setoran tertunda', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingDeposits.length,
      itemBuilder: (context, index) {
        final deposit = _pendingDeposits[index];
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
                          Text(
                            deposit.userEmail,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          ),
                          Text(
                            'ID: ${deposit.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Reject logic could be here
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approveDeposit(deposit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Setujui (ACC)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
