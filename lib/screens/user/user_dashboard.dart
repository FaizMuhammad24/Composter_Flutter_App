import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'user_deposit_screen.dart';
import 'user_deposit_history_screen.dart';
import 'user_rewards_screen.dart';
import 'widgets/user_header.dart';

class UserDashboard extends StatefulWidget {
  final UserModel user;

  const UserDashboard({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // HEADER
      appBar: const UserHeader(),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // Light green top
              Color(0xFFF5F5DC), // Beige bottom
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HERO CARD (dengan statistik di dalamnya)
                _buildHeroCard(),

            const SizedBox(height: 24),

            // 2. QUICK ACTION
            _buildQuickActions(),

            const SizedBox(height: 24),

            // 3. REWARD TERPOPULER
            _buildPopularRewards(),

            const SizedBox(height: 24),

            // 4. TIPS KOMPOS
            _buildKomposTips(),

            const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== 1. HERO CARD ==========
  Widget _buildHeroCard() {
    return Container(
      height: 300,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D5016), Color(0xFF6B8E23)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dekorasi background
          Positioned(
            top: 16,
            right: 16,
            child: Icon(
              Icons.local_florist,
              size: 70,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 90,
            right: 32,
            child: Icon(
              Icons.spa,
              size: 40,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          // Greeting
          Positioned(
            top: 24,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hai, Selamat Datang!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Statistik Bulan Ini (di dalam hero)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik Bulan Ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildHeroStatCard('🗑️', '12 kg', 'Disetor'),
                    const SizedBox(width: 10),
                    _buildHeroStatCard('⭐', '${widget.user.points ?? 0}', 'Poin'),
                    const SizedBox(width: 10),
                    _buildHeroStatCard('🎁', '2x', 'Ditukar'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 2. QUICK ACTION ==========
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ Quick Action',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                icon: '🗑️',
                label: 'Setor\nSampah',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDepositScreen(userEmail: widget.user.email),
                  ),
                ),
              ),
              _buildActionButton(
                icon: '📊',
                label: 'Riwayat Setor Sampah',
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserDepositHistoryScreen()),
                ),
              ),
              _buildActionButton(
                icon: '🎁',
                label: 'Tukar\nPoin',
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserRewardsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== 4. REWARD TERPOPULER ==========
  Widget _buildPopularRewards() {
    final rewards = [
      {'name': 'Voucher\nAlfamart', 'points': '500', 'stars': 5, 'image': '🎫'},
      {'name': 'Pupuk\nOrganik', 'points': '300', 'stars': 4, 'image': '🌱'},
      {'name': 'Bibit\nTanaman', 'points': '200', 'stars': 5, 'image': '🌿'},
      {'name': 'Tas\nBelanja', 'points': '150', 'stars': 4, 'image': '👜'},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎁 Reward Terpopuler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                  fontFamily: 'Poppins',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserRewardsScreen()),
                ),
                child: const Text(
                  'Lihat Semua →',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              return _buildRewardCard(
                name: reward['name'] as String,
                points: reward['points'] as String,
                stars: reward['stars'] as int,
                image: reward['image'] as String,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard({
    required String name,
    required String points,
    required int stars,
    required String image,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[200]!, Colors.orange[100]!],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Text(image, style: const TextStyle(fontSize: 50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$points pts',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 13,
                      color: i < stars ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    // ========== 3. TIPS KOMPOS ==========
  Widget _buildKomposTips() {
    final tips = [
      {
        'icon': '🌿',
        'title': 'Campur Hijau & Coklat',
        'desc': 'Padukan sampah hijau (sisa makanan) dan coklat (daun kering).',
        'color': const Color(0xFF4CAF50),
      },
      {
        'icon': '💧',
        'title': 'Jaga Kelembaban',
        'desc': 'Pastikan kompos lembab seperti spons basah, tidak terlalu kering atau becek.',
        'color': const Color(0xFF2196F3),
      },
      {
        'icon': '🔄',
        'title': 'Aduk Rutin',
        'desc': 'Aduk tumpukan kompos setiap 2-3x/hari agar oksigen merata',
        'color': const Color(0xFFFF9800),
      },
      {
        'icon': '🌡️',
        'title': 'Suhu Ideal',
        'desc': 'Kompos aktif bisa mencapai 55–65°C — itu tanda fermentasi berhasil!',
        'color': const Color(0xFFE91E63),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '💡 Tips Kompos Hari Ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              final color = tip['color'] as Color;
              return Container(
                width: 195,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tip['icon'] as String,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tip['desc'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }



}
