import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'emailjs_service.dart';

class SignupService {
  static Future<Map<String, dynamic>> signUpUser({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    email = email.toLowerCase().trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Semua field harus diisi'};
    }
    if (!email.contains('@')) {
      return {'success': false, 'message': 'Format email tidak valid'};
    }
    if (password.length < 6) {
      return {'success': false, 'message': 'Password minimal 6 karakter'};
    }
    if (password != confirmPassword) {
      return {'success': false, 'message': 'Password dan konfirmasi password tidak sama'};
    }

    try {
      // Buat OTP 6 digit
      String otpCode = (100000 + Random().nextInt(900000)).toString();

      // Kirim email via EmailJS
      bool emailSent = await EmailJSService.sendOtpEmail(email, otpCode);

      if (emailSent) {
        return {
          'success': true,
          'message': 'OTP berhasil dikirim',
          'otp': otpCode,
          'userData': {
            'name': name,
            'email': email,
            'password': password,
          }
        };
      } else {
        return {'success': false, 'message': 'Gagal mengirim email OTP. Silakan coba lagi.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  static Future<Map<String, dynamic>> finalizeSignup(Map<String, dynamic> userData) async {
    String email = userData['email'];
    String password = userData['password'];
    String name = userData['name'];

    try {
      // Buat User di Firebase Auth
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        String uid = cred.user!.uid;
        String role = 'user';

        // Trik Migrasi: Cek jika akun ini sblmnya dibuat via web Firestore dgn ID acak
        var existingDocs = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
        if (existingDocs.docs.isNotEmpty) {
          role = existingDocs.docs.first.data()['role'] ?? 'user';
          // Hapus dokumen lama yang ber-ID acak
          await FirebaseFirestore.instance.collection('users').doc(existingDocs.docs.first.id).delete();
        }

        var newUser = {
          'uid': uid,
          'name': name,
          'email': email,
          'role': role,
          'points': 0,
          'created_at': DateTime.now().toIso8601String(),
        };

        // Simpan ke Firestore menggunakan Auth UID
        await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser);
        
        // Akun otomatis terverifikasi karena OTP sudah berhasil
        var userModel = UserModel.fromJson(newUser);

        return {
          'success': true,
          'message': 'Registrasi berhasil!',
          'user': userModel,
        };
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return {'success': false, 'message': 'Email sudah terdaftar'};
      }
      return {'success': false, 'message': e.message ?? 'Gagal mendaftar'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem'};
    }

    return {'success': false, 'message': 'Registrasi gagal'};
  }
}