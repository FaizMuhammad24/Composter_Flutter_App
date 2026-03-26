import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'constants/app_colors.dart';
import 'screens/authentication/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase Initialized Successfully!");
    }
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }
  
  runApp(const KomposApp());
}

class KomposApp extends StatelessWidget {
  const KomposApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kompos Monitoring System',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          error: AppColors.error,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFFFFA726), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
        
        dividerTheme: DividerThemeData(
          color: Colors.grey[300],
          thickness: 1,
          space: 24,
        ),
        
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.primary,
          contentTextStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        useMaterial3: true,
      ),
      
      home: const SplashScreen(),
    );
  }
}
