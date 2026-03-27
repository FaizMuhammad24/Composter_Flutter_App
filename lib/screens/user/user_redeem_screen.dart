import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/user/user_service.dart';
import '../../services/rewards/reward_service.dart';
import '../../services/notifications/user_notification_service.dart';
import '../../services/notifications/super_admin_notification_service.dart';
import '../../models/user_model.dart';

class UserRedeemScreen extends StatefulWidget {
  final String userEmail;
  final String rewardName;
  final String rewardId;
  final int pointsPerItem;
  final IconData icon;
  final Color color;
  final String imageUrl;

  const UserRedeemScreen({
    Key? key, 
    required this.userEmail,
    required this.rewardName, 
    required this.rewardId,
    required this.pointsPerItem,
    required this.icon,
    required this.color,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<UserRedeemScreen> createState() => _UserRedeemScreenState();
}

class _UserRedeemScreenState extends State<UserRedeemScreen> {
  int _quantity = 1;
  int _userPoints = 0;
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = await UserService.getUserByEmail(widget.userEmail);
    if (user != null && mounted) {
      setState(() {
        _userModel = user;
        _userPoints = user.points ?? 0;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _increment() {
    if ((_quantity + 1) * widget.pointsPerItem <= _userPoints) {
      setState(() => _quantity++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poin Anda tidak mencukupi untuk menambah jumlah ini.', style: TextStyle(fontFamily: 'Poppins')), 
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  Future<void> _handleRedeem() async {
    final int totalRequired = _quantity * widget.pointsPerItem;

    if (totalRequired > _userPoints) return;

    setState(() => _isLoading = true);
    
    try {
      // 1. Buat klaim ke Firestore (poin TIDAK langsung dipotong)
      await RewardService.createClaim(
        userEmail: widget.userEmail,
        userName: _userModel?.name ?? 'Pengguna',
        rewardId: widget.rewardId,
        rewardName: widget.rewardName,
        quantity: _quantity,
        totalPoints: totalRequired,
      );

      // 2. Notifikasi User bahwa klaim sedang menunggu konfirmasi SA
      await UserNotificationService.notifyRewardRedeemed(
        widget.userEmail, 
        '${_quantity}x ${widget.rewardName}',
      );

      // 3. Notifikasi Super Admin ada permintaan klaim baru
      await SuperAdminNotificationService.notifyRewardRequest(
        userEmail: widget.userEmail,
        userName: _userModel?.name ?? 'Pengguna',
        rewardName: '${_quantity}x ${widget.rewardName}',
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan klaim: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConfirmDialog() {
    final int totalRequired = _quantity * widget.pointsPerItem;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Klaim', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menukar $totalRequired poin dengan $_quantity item ${widget.rewardName}?', style: const TextStyle(fontFamily: 'Poppins')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleRedeem();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Klaim', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 60),
            ),
            const SizedBox(height: 24),
            const Text('Klaim Terkirim!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            const Text(
              'Permintaan klaim Anda sedang menunggu konfirmasi SuperAdmin. Poin akan dikurangi otomatis setelah disetujui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pantau status klaim di tab Riwayat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontFamily: 'Poppins', fontSize: 11),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup Dialog
                  Navigator.pop(context); // Kembali ke Reward List
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('OK', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final int totalRequired = _quantity * widget.pointsPerItem;
    final bool canAfford = totalRequired <= _userPoints;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Klaim', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // CARD ITEM
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: widget.color.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        if (widget.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.imageUrl,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: widget.color.withOpacity(0.15), shape: BoxShape.circle),
                                child: Icon(widget.icon, size: 80, color: widget.color),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: widget.color.withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(widget.icon, size: 80, color: widget.color),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          widget.rewardName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.pointsPerItem} Pts / item',
                          style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // INFO KLAIM
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Poin TIDAK langsung dipotong. Klaim perlu dikonfirmasi SuperAdmin terlebih dahulu. Setelah disetujui, poin baru dikurangi.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.5, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // KUANTITAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jumlah Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _decrement,
                              color: _quantity > 1 ? Colors.black87 : Colors.grey,
                            ),
                            Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _increment,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

                  // RINGKASAN POIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Poin Klaim', style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey)),
                      Text('$totalRequired Pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Poin Anda Saat Ini', style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey)),
                      Text('$_userPoints Pts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: canAfford ? Colors.black87 : Colors.red)),
                    ],
                  ),
                  if (!canAfford) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Poin tidak mencukupi', style: TextStyle(color: Colors.red, fontFamily: 'Poppins', fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // TOMBOL KONFIRMASI
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (canAfford && !_isLoading) ? _showConfirmDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Ajukan Klaim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
