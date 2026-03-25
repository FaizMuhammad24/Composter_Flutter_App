import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../authentication/login_screen.dart';
import '../authentication/reset_password_screen.dart';
import '../../services/auth/session_service.dart';
import '../../services/notifications/notification_service.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  StreamSubscription<DatabaseEvent>? _rtdbSubscription;
  bool _isOffline = true;
  int _sensorCount = 0;
  int _activeAlerts = 0;
  DateTime? _lastUpdate;
  Timer? _offlineCheckTimer;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
    _startOfflineTimer();
  }

  @override
  void dispose() {
    _rtdbSubscription?.cancel();
    _offlineCheckTimer?.cancel();
    super.dispose();
  }

  bool _isDataStale(Map<dynamic, dynamic> data) {
    // 1. Cek via Unix Timestamp (Paling robust)
    if (data.containsKey('unix_time')) {
      final int espUnix = (data['unix_time'] as num).toInt();
      final int phoneUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final diff = (phoneUnix - espUnix).abs();
      return diff > 60; // 1 Minute tolerance
    }

    // 2. Fallback ke String "time" (HH:mm:ss)
    final String? timeStr = data['time']?.toString();
    if (timeStr == null || timeStr.isEmpty) return true;
    try {
      final parts = timeStr.split(':');
      if (parts.length != 3) return true;
      final now = DateTime.now();
      final dataTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return now.difference(dataTime).inSeconds.abs() > 60;
    } catch (e) {
      return true;
    }
  }
  void _startOfflineTimer() {
    _offlineCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastUpdate == null) return;
      final diff = DateTime.now().difference(_lastUpdate!);
      if (diff.inSeconds > 20 && !_isOffline) {
        setState(() {
          _isOffline = true;
          _sensorCount = 0;
          _activeAlerts = 0;
        });
      }
    });
  }

  void _listenToFirebase() {
    _rtdbSubscription = FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final bool stale = _isDataStale(data);
        
        final temp = (data['temperature'] as num?)?.toDouble() ?? 0;
        final soil = (data['soil'] as num?)?.toDouble() ?? 0;
        final ph = (data['ph'] as num?)?.toDouble() ?? 0;
        final gas = (data['gas'] as num?)?.toDouble() ?? 0;


        int healthyCount = 0;
        if (temp != 100.0 && temp != 0.0) healthyCount++;
        if (soil != 100.0 && soil != 0.0) healthyCount++;
        if (ph != 100.0 && ph != 10.0 && ph != 0.0) healthyCount++;
        if (gas != 100 && gas != 100.0 && gas != 0.0) healthyCount++;

        // Count active actuators
        int activeActuators = 0;
        final actuators = data['actuators'] as Map? ?? {};
        actuators.forEach((key, value) {
          if (value == true) activeActuators++;
        });

        if (mounted) {
          setState(() {
            _isOffline = stale;
            if (!stale) _lastUpdate = DateTime.now();
            _sensorCount = stale ? 0 : healthyCount; 
            _activeAlerts = stale ? 0 : activeActuators; // Using same variable name but for actuator count now
          });
        }
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final user = SessionService.getCurrentUser();
    final screenHeight = MediaQuery.of(context).size.height;
    final headerH = (screenHeight * 0.36).clamp(220.0, 290.0);

    return Container(
      color: AppColors.adminPrimary,
      child: Column(
        children: [
          // ── Header (orange zone) ──────────────────────────────
          SizedBox(
            height: headerH,
            child: _buildHeader(user),
          ),

          // ── White card panel ──────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.adminBg,
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
                    // Stats row
                    _buildStatsCard(),
                    const SizedBox(height: 28),

                    // Menu tiles
                    _buildMenuTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Ubah Password',
                      subtitle: 'Ganti kata sandi akun Anda',
                      color: AppColors.adminPrimary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResetPasswordScreen(email: user?.email),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuTile(
                      icon: Icons.logout_rounded,
                      title: 'Keluar',
                      subtitle: 'Log out dari akun Admin',
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

  Widget _buildHeader(dynamic user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
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
                backgroundColor: AppColors.adminPrimary,
                child: Icon(Icons.shield_outlined, size: 50, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user?.name ?? 'Admin Kompos',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user?.email ?? 'admin@kompos.com',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: const Text(
              'Administrator',
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
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminPrimary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('Status', _isOffline ? 'Offline' : 'Online', _isOffline ? Colors.grey : Colors.green),
          _buildDivider(),
          _buildStat('Sistem', '$_sensorCount Sensor', _sensorCount == 0 ? Colors.grey : (_sensorCount == 4 ? Colors.green : Colors.red)),
          _buildDivider(),
          _buildStat('Alat', '$_activeAlerts Aktif', _activeAlerts > 0 ? Colors.yellow.shade700 : Colors.grey),
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
              color: isDestructive ? Colors.red.shade100 : Colors.orange.shade100,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun Admin?',
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
                  child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins', color: Colors.black87)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    NotificationService().dispose();
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
                  child: const Text('Keluar', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
