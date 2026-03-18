import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'user_profile_screen.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({Key? key}) : super(key: key);

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Agar dibelakang CurvedNav warnanya clear
      
      // HEADER SESUAI DASHBOARD
      appBar: AppBar(
        backgroundColor: AppColors.primary, // Warna hijau dashboard
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, color: AppColors.primary, size: 20),
          ),
        ),
        title: const Text(
          'I-Compost',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifikasi (Coming Soon)')),
              );
            },
          ),
        ],
      ),
      
      body: Container(
        color: AppColors.primary, // Bagian atas nyambung dengan header
        child: Column(
          children: [
            // TOP SECTION: BALANCE & CARDS
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Poin Anda',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2.450 Pts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Card Kiri (Light Blue seperti gambar)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF81D4FA), // biru muda
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '15 kg',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Total Setor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Card Kanan (Orange seperti gambar)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D), // oranye
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '3x',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Reward Ditukar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // BOTTOM SECTION: TRANSACTION LIST
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        'Riwayat Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _buildTransactionItem(
                            icon: Icons.recycling,
                            iconColor: const Color(0xFF4CAF50), // Hijau
                            title: 'Setor Sampah Organik',
                            subtitle: 'Dapur & Sisa Makanan',
                            amount: '+150 Pts',
                            amountColor: Colors.black87,
                          ),
                          _buildTransactionItem(
                            icon: Icons.card_giftcard,
                            iconColor: const Color(0xFF3F51B5), // Biru gelap
                            title: 'Voucher Alfamart',
                            subtitle: 'Reward Ditukar',
                            amount: '-500 Pts',
                            amountColor: Colors.black87,
                          ),
                          _buildTransactionItem(
                            icon: Icons.local_florist,
                            iconColor: const Color(0xFFFF5722), // Merah bata
                            title: 'Pupuk Kompos',
                            subtitle: 'Reward Ditukar',
                            amount: '-250 Pts',
                            amountColor: Colors.black87,
                          ),
                          _buildTransactionItem(
                            icon: Icons.delete_outline,
                            iconColor: const Color(0xFF26C6DA), // Biru tosca
                            title: 'Setor Daun Kering',
                            subtitle: 'Sampah Cokelat',
                            amount: '+50 Pts',
                            amountColor: Colors.black87,
                          ),
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

      // BOTTOM NAVIGATION SESUAI DASHBOARD
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: amountColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return CurvedNavigationBar(
      index: 1, // 1 = History
      height: 60.0,
      backgroundColor: Colors.white, // Harus putih supaya nyambung dengan background list bawah
      color: AppColors.primary,
      buttonBackgroundColor: AppColors.primary,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      items: const <Widget>[
        Icon(Icons.home, size: 30, color: Colors.white),
        Icon(Icons.history, size: 30, color: Colors.white),
        Icon(Icons.person_outline, size: 30, color: Colors.white),
      ],
      onTap: (index) {
        if (index == 1) return; // Sudah di History
        
        if (index == 0) {
          Navigator.pop(context); // Kembali ke Dashboard/Home
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const UserProfileScreen(),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      },
    );
  }
}
