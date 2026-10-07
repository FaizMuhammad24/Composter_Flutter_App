import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CreditsScreen extends StatelessWidget {
  final bool isAdmin;

  const CreditsScreen({Key? key, this.isAdmin = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = isAdmin ? AppColors.adminPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Kredit Aplikasi',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── App Header Banner ──────────────────────────────────
            _buildAppHeader(themeColor),
            const SizedBox(height: 24),

            // ── Section 1: Tim Pengembang ──────────────────────────
            _buildSectionHeader('Tim Pengembang', Icons.code_rounded, themeColor),
            const SizedBox(height: 12),
            // Nama 1: Hardware (Tanpa Border)
            _buildMemberCard(
              name: 'Muhammad Ilham Ananta',
              role: 'Hardware',
              icon: Icons.developer_board_rounded,
              color: Colors.blue.shade700,
              hasBorder: false,
            ),
            const SizedBox(height: 10),
            // Nama 2: Software
            _buildMemberCard(
              name: 'Tubagus Muhammad Rofi Al Faiz',
              role: 'Software',
              icon: Icons.phone_android_rounded,
              color: Colors.blue,
              hasBorder: true,
            ),
            const SizedBox(height: 24),

            // ── Section 2: Dosen Pembimbing ───────────────────────
            _buildSectionHeader('Dosen Pembimbing', Icons.school_rounded, themeColor),
            const SizedBox(height: 12),
            _buildMemberCard(
              name: 'Shita Fitria Nurjihan, S.T., M.T.',
              role: 'Dosen Pembimbing I',
              icon: Icons.verified_user_rounded,
              color: Colors.amber.shade800,
              hasBorder: true,
            ),
            const SizedBox(height: 10),
            _buildMemberCard(
              name: 'Hana Kamilia Adiningtyas, S.T., M.T.',
              role: 'Dosen Pembimbing II',
              icon: Icons.verified_user_outlined,
              color: Colors.amber.shade700,
              hasBorder: true,
            ),
            const SizedBox(height: 10),
            _buildMemberCard(
              name: 'Ainnur Rahayu Pratiwi, S.T., M.T.',
              role: 'Dosen Pembimbing III',
              icon: Icons.verified_user_outlined,
              color: Colors.amber.shade600,
              hasBorder: true,
            ),
            const SizedBox(height: 24),

            // ── Section 3: Dosen Teknik Elektro & Telekomunikasi PNJ ─
            _buildSectionHeader(
              'Apresiasi & Ucapan Terima Kasih',
              Icons.groups_rounded,
              themeColor,
            ),
            const SizedBox(height: 12),
            _buildLecturersCollectiveCard(themeColor),
            const SizedBox(height: 32),

            // ── Footer ─────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    'i-COMPOST',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 Politeknik Negeri Jakarta\nJurusan Teknik Elektro - Prodi Telekomunikasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey[400],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(Color themeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/logo.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.compost_rounded, size: 48, color: themeColor),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'i-COMPOST',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sistem Monitoring & Manajemen Komposter Otomatis Berbasis IoT',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Politeknik Negeri Jakarta',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: themeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color themeColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: themeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard({
    required String name,
    required String role,
    String? subtitle,
    required IconData icon,
    required Color color,
    bool hasBorder = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: hasBorder ? Border.all(color: Colors.grey.shade200, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturersCollectiveCard(Color themeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, color: themeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seluruh Dosen Teknik Elektro &\nProdi Teknik Telekomunikasi PNJ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Terima kasih yang sebesar-besarnya atas segala bimbingan, arahan, ilmu pengetahuan, dan dukungan yang telah diberikan selama masa studi dan penyusunan Tugas Akhir ini.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
