import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class UserNotificationsScreen extends StatelessWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar abu-abu sangat muda agar kartu notif menonjol
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Tombol back warna putih
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Hari ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'Berhasil Setor Sampah 🎉',
            description: 'Hebat! Sampah organik seberat 5kg telah berhasil divalidasi dan ditambahkan ke riwayatmu. Terus semangat ya!',
            date: '18 Mar 2026 • 14:30',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            isUnread: true,
          ),
          _buildNotificationCard(
            title: 'Reward Berhasil Ditukar',
            description: 'Kamu baru saja menukarkan 500 Pts dengan Voucher Alfamart Rp50.000. Cek detail tiketmu segera.',
            date: '18 Mar 2026 • 09:15',
            icon: Icons.card_giftcard,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            isUnread: false,
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Kemarin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'Gagal Setor Sampah ⚠️',
            description: 'Mohon maaf, setoran kamu dibatalkan karena terdeteksi banyak sampah plastik (anorganik) di dalam kresek hijau.',
            date: '17 Mar 2026 • 16:45',
            icon: Icons.cancel,
            iconColor: Colors.red,
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            isUnread: false,
          ),
          _buildNotificationCard(
            title: 'Peringatan Sistem',
            description: 'Ada jadwal perbaikan alat komposter area kecamatanmu besok pagi. Mesin mungkin tidak dapat digunakan dari jam 08:00 - 12:00.',
            date: '17 Mar 2026 • 10:00',
            icon: Icons.warning_rounded,
            iconColor: Colors.orange,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required String date,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isUnread ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5) : Border.all(color: Colors.grey[100]!),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Bulat
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Konten Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Indikator Titik Merah Unread
          if (isUnread)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
