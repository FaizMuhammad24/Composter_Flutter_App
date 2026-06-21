import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../services/user/points_service.dart';
import '../../../services/notifications/user_notification_service.dart';
import '../../../services/notifications/management_notification_service.dart';

class AdminDepositApprovalScreen extends StatefulWidget {
  const AdminDepositApprovalScreen({Key? key}) : super(key: key);

  @override
  State<AdminDepositApprovalScreen> createState() => _AdminDepositApprovalScreenState();
}

class _AdminDepositApprovalScreenState extends State<AdminDepositApprovalScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deposits = [];
  String _filter = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('composts')
          .where('status', isEqualTo: _filter)
          .get();

      final deposits = snap.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      // Sort client-side by createdAt descending
      deposits.sort((a, b) {
        final dateA = a['createdAt']?.toString() ?? '';
        final dateB = b['createdAt']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });

      if (mounted) setState(() { _deposits = deposits; _isLoading = false; });
    } catch (e) {
      debugPrint('Error loading deposits: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading deposits: $e')));
      }
    }
  }

  void _showDepositDetail(Map<String, dynamic> deposit) {
    final dateStr = _formatDate(deposit['createdAt']);
    final weight = (deposit['weight'] as num?)?.toDouble() ?? 0.0;
    final points = (deposit['points'] as num?)?.toInt() ?? 0;
    final imageUrl = deposit['imageUrl']?.toString() ?? '';
    final email = deposit['userEmail']?.toString() ?? '-';
    final status = deposit['status']?.toString() ?? 'pending';

    final urls = imageUrl.split(',').where((u) => u.trim().isNotEmpty).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Detail Setoran Kompos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              const SizedBox(height: 16),

              // Image(s)
              if (urls.isNotEmpty)
                Builder(
                  builder: (context) {
                    if (urls.length == 1) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          urls.first,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                            child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                          ),
                          loadingBuilder: (_, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 220,
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                              child: const Center(child: CircularProgressIndicator(color: AppColors.adminPrimary, strokeWidth: 2)),
                            );
                          },
                        ),
                      );
                    } else {
                      return SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: urls.length,
                          itemBuilder: (ctx, idx) => Container(
                            width: MediaQuery.of(context).size.width - 72,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                urls[idx],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                                loadingBuilder: (_, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator(color: AppColors.adminPrimary, strokeWidth: 2));
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                )
              else
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Text('Tidak ada foto', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'))),
                ),

              const SizedBox(height: 20),

              // Info rows
              _buildInfoRow(Icons.email_outlined, 'Email User', email),
              _buildInfoRow(Icons.scale, 'Berat Sampah', '${weight.toStringAsFixed(1)} kg'),
              _buildInfoRow(Icons.stars, 'Poin Dihitung', '$points pts'),
              _buildInfoRow(Icons.calendar_today, 'Tanggal', dateStr),
              _buildInfoRow(Icons.flag, 'Status', status == 'pending' ? 'Menunggu' : status == 'approved' ? 'Disetujui' : 'Ditolak'),

              const SizedBox(height: 24),

              // Actions for pending
              if (status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _rejectDeposit(deposit);
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveDeposit(deposit);
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Terima', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.adminPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.adminPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Poppins')),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveDeposit(Map<String, dynamic> deposit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terima Setoran', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(
          'Setujui setoran ${(deposit["weight"] as num).toStringAsFixed(1)} kg dari ${deposit["userEmail"]}?\n\nPoin: +${deposit["points"]} pts',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terima', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final docId = deposit['docId'] ?? deposit['id'];
        await FirebaseFirestore.instance.collection('composts').doc(docId).update({
          'status': 'approved',
          'approvedAt': DateTime.now().toIso8601String(),
        });

        await PointsService.addUserPoints(
          userEmail: deposit['userEmail'],
          pointsToAdd: (deposit['points'] as num).toInt(),
        );

        await UserNotificationService.notifyDepositApproved(
          deposit['userEmail'],
          (deposit['weight'] as num).toDouble(),
          (deposit['points'] as num).toInt(),
        );

        await ManagementNotificationService.clearDepositNotification(
          deposit['userEmail'],
          (deposit['weight'] as num).toDouble(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran disetujui & poin ditambahkan!'), backgroundColor: Colors.green),
        );
        _loadDeposits();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectDeposit(Map<String, dynamic> deposit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tolak Setoran', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('Tolak setoran ${(deposit["weight"] as num).toStringAsFixed(1)} kg dari ${deposit["userEmail"]}?', style: const TextStyle(fontFamily: 'Poppins')),
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
        final docId = deposit['docId'] ?? deposit['id'];
        await FirebaseFirestore.instance.collection('composts').doc(docId).update({'status': 'rejected'});

        await UserNotificationService.notifyDepositRejected(
          deposit['userEmail'],
          (deposit['weight'] as num).toDouble(),
        );

        await ManagementNotificationService.clearDepositNotification(
          deposit['userEmail'],
          (deposit['weight'] as num).toDouble(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran ditolak'), backgroundColor: Colors.orange),
        );
        _loadDeposits();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(dynamic dateStr) {
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('dd MMM yyyy, HH:mm', 'id').format(dt);
    } catch (_) {
      return dateStr?.toString() ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        title: const Text('Setoran Kompos', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.adminPrimary))
                : _deposits.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadDeposits,
                        color: AppColors.adminPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _deposits.length,
                          itemBuilder: (_, i) => _buildDepositCard(_deposits[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildChip('Menunggu', 'pending', Colors.orange),
            const SizedBox(width: 10),
            _buildChip('Disetujui', 'approved', Colors.green),
            const SizedBox(width: 10),
            _buildChip('Ditolak', 'rejected', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _loadDeposits();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins',
          color: isSelected ? Colors.white : Colors.grey[600],
        )),
      ),
    );
  }

  Widget _buildEmpty() {
    final emptyText = _filter == 'pending' ? 'Tidak ada setoran menunggu' : _filter == 'approved' ? 'Belum ada yang disetujui' : 'Belum ada yang ditolak';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(emptyText, style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDepositCard(Map<String, dynamic> deposit) {
    final weight = (deposit['weight'] as num?)?.toDouble() ?? 0;
    final points = (deposit['points'] as num?)?.toInt() ?? 0;
    final email = deposit['userEmail']?.toString() ?? '-';
    final dateStr = _formatDate(deposit['createdAt']);
    final imageUrl = deposit['imageUrl']?.toString() ?? '';
    final firstImageUrl = imageUrl.split(',').firstWhere((u) => u.trim().isNotEmpty, orElse: () => '');
    final isPending = _filter == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDepositDetail(deposit),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                // Thumbnail image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: firstImageUrl.isNotEmpty
                      ? Image.network(
                          firstImageUrl,
                          width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56, height: 56,
                            color: Colors.grey[100],
                            child: const Icon(Icons.compost, color: Colors.green, size: 28),
                          ),
                        )
                      : Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.compost, color: Colors.green, size: 28),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${weight.toStringAsFixed(1)} kg  •  $dateStr', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('+$points pts', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.amber)),
                      ),
                    ],
                  ),
                ),
                if (isPending) ...[
                  IconButton(
                    onPressed: () => _rejectDeposit(deposit),
                    icon: Icon(Icons.close, color: Colors.red[400], size: 20),
                    tooltip: 'Tolak',
                    splashRadius: 20,
                  ),
                  IconButton(
                    onPressed: () => _approveDeposit(deposit),
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                    tooltip: 'ACC',
                    splashRadius: 20,
                  ),
                ] else
                  Icon(
                    _filter == 'approved' ? Icons.check_circle : Icons.cancel,
                    color: _filter == 'approved' ? Colors.green : Colors.red,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
