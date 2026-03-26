import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../authentication/login_screen.dart';
import '../authentication/reset_password_screen.dart';
import '../../services/auth/session_service.dart';
import '../../services/history/history_service.dart';
import '../../services/user/user_service.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user;
  const UserProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  double _totalWeight = 0;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // 1. Reload user data for points
      final freshUser = await UserService.getUserByEmail(_currentUser.email);
      if (freshUser != null && mounted) {
        setState(() => _currentUser = freshUser);
      }

      // 2. Reload history for stats
      final history = await HistoryService.getUserHistory(_currentUser.email);
      double weightSum = 0;
      for (var item in history) {
        weightSum += item.weight;
      }
      if (mounted) {
        setState(() {
          _totalWeight = weightSum;
        });
      }
    } catch (e) {
      // Error loading stats
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final screenHeight = MediaQuery.of(context).size.height;
    // Dynamic header height: 36% of screen, clamped between 230–300px
    final headerH = (screenHeight * 0.38).clamp(230.0, 300.0);

    return Container(
      color: AppColors.primary, // Dark green header zone
      child: Column(
        children: [
          // ── Header (green zone) ─────────────────────────────
          SizedBox(
            height: headerH,
            child: _buildHeader(user),
          ),

          // ── White card panel ────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
                child: Column(
                  children: [
                    // Stats card
                    _buildStatsCard(user),
                    const SizedBox(height: 28),

                    // Menu: Ubah Password
                    _buildMenuTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Ubah Password',
                      subtitle: 'Ganti kata sandi akun Anda',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResetPasswordScreen(email: user.email),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Menu: Keluar
                    _buildMenuTile(
                      icon: Icons.logout_rounded,
                      title: 'Keluar',
                      subtitle: 'Log out dari akun Anda',
                      color: Colors.red,
                      isDestructive: true,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Header ────────────────────────────────
  Widget _buildHeader(UserModel user) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Double-ring avatar (same style as admin/super admin)
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_rounded, size: 50, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Name
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 3),

            // UID (Ganti Email - Dipersingkat)
            Text(
              'ID: ${user.uid.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: const Text(
                'Pengguna Kompos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Stats Card ─────────────────────────────
  Widget _buildStatsCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('Poin', '${_currentUser.points ?? 0}', Colors.orange),
          _buildDivider(),
          _buildStat('Disetor', '${_totalWeight.toStringAsFixed(1)} kg', Colors.green),
          _buildDivider(),
          _buildStat('Reward', '0x', Colors.blue), // Hardcoded for now till RewardService
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins'),
        ),
      ],
    );
  }

  Widget _buildDivider() =>
      Container(height: 36, width: 1, color: Colors.grey.shade200);

  // ─────────────────────────── Menu Tile ──────────────────────────────
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive ? Colors.red.shade100 : Colors.green.shade100,
            ),
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red : Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing icon
              Icon(
                isDestructive ? Icons.logout_rounded : Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDestructive ? Colors.red : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Logout Dialog ──────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Keluar?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun?',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await SessionService.logout();
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
