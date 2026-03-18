import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../user/user_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../super_admin/super_admin_dashboard.dart';
import '../../services/auth/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Tunggu 3 detik sesuai durasi splash
    await Future.delayed(const Duration(seconds: 3));
    
    // Inisialisasi session (cek SharedPreferences)
    await SessionService.init();

    if (!mounted) return;

    if (SessionService.isLoggedIn()) {
      final user = SessionService.getCurrentUser()!;
      Widget nextScreen;

      if (user.role == 'super_admin') {
        nextScreen = const SuperAdminDashboard();
      } else if (user.role == 'admin') {
        nextScreen = const AdminDashboard();
      } else {
        nextScreen = UserDashboard(user: user);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D5016),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150, height: 150,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.eco, size: 80, color: Color(0xFF2D5016)),
            ),
            const SizedBox(height: 24),
            const Text('Kompos', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
