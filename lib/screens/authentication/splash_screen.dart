import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../user/user_main_screen.dart';
import '../admin/admin_main_screen.dart';
import '../super_admin/super_admin_main_screen.dart';
import '../../services/auth/session_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../constants/app_colors.dart';

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

      if (user.role == 'super_admin' || user.role == 'admin') {
        await NotificationService().init();
      }

      if (user.role == 'super_admin') {
        nextScreen = const SuperAdminMainScreen();
      } else if (user.role == 'admin') {
        nextScreen = const AdminMainScreen();
      } else {
        nextScreen = UserMainScreen(user: user);
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
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo: White circle + Green Eco icon (Official Brand)
            Container(
              width: 140, 
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white, 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            const Text(
              'I-Compost', 
              style: TextStyle(
                fontSize: 42, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                fontFamily: 'Poppins',
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'by Politeknik Negeri Jakarta',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                fontFamily: 'Poppins',
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
