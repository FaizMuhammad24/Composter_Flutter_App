import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/user/user_service.dart';
import '../../services/user/points_service.dart';
import '../../services/notifications/user_notification_service.dart';
import '../../services/notifications/super_admin_notification_service.dart';
import '../../models/user_model.dart';

class UserRedeemScreen extends StatefulWidget {
  final String userEmail;
  final String rewardName;
  final int pointsPerItem;
  final IconData icon;
  final Color color;

  const UserRedeemScreen({
    Key? key, 
    required this.userEmail,
    required this.rewardName, 
    required this.pointsPerItem,
    required this.icon,
    required this.color,
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
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poin Anda tidak mencukupi untuk menambah jumlah ini.', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: Colors.red),
      );
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _handleRedeem() async {
    final int totalRequired = _quantity * widget.pointsPerItem;
    final int remainingPoints = _userPoints - totalRequired;

    if (remainingPoints < 0) return;

    setState(() => _isLoading = true);
    
    try {
      // 1. Potong Poin
      final result = await PointsService.updateUserPoints(
        userEmail: widget.userEmail, 
        points: remainingPoints,
      );

      if (result['success']) {
        // 2. Notifikasi User
        await UserNotificationService.notifyRewardRedeemed(
          widget.userEmail, 
          widget.rewardName,
        );

        // 3. Notifikasi Super Admin (Peringatan Hadiah Baru)
        await SuperAdminNotificationService.notifyRewardRequest(
          userEmail: widget.userEmail,
          userName: _userModel?.name ?? 'Pengguna',
          rewardName: '${_quantity}x ${widget.rewardName}',
        );

        if (!mounted) return;
        _showSuccessDialog();
      } else {
        throw Exception(result['message'] ?? 'Gagal memproses penukaran');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 24),
            const Text('Penukaran Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            const Text(
              'Silakan hubungi Admin / Loket Terdekat untuk pengambilan hadiah dengan menunjukkan riwayat penukaran Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Poin Anda telah dipotong secara otomatis.',
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
                child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
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
    final int remainingPoints = _userPoints - totalRequired;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Penukaran', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white)),
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

                  const SizedBox(height: 24),

                  // KETERANGAN PENGAMBILAN
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Instruksi Pengambilan:\nHadiah dapat diambil di loket panitia / Drop Point terdekat dengan memberikan konfirmasi kepada Admin.',
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
                      const Text(
                        'Jumlah Item',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _decrement,
                              color: _quantity > 1 ? Colors.black87 : Colors.grey,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                            ),
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

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  // RINGKASAN POIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey)),
                      Text('$totalRequired Pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sisa Poin Anda', style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey)),
                      Text('$remainingPoints Pts', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // TOMBOL KONFIRMASI (BOTTOM)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (remainingPoints >= 0 && !_isLoading) ? _handleRedeem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Konfirmasi Tukar Poin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
