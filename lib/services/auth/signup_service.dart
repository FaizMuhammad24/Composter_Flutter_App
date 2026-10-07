import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class SignupService {
  static Future<Map<String, dynamic>> signUpUser({
    required String name,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    username = username.toLowerCase().replaceAll(RegExp(r'[\s@]+'), '').trim();
    String email = '$username@icompost.app';

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Semua field harus diisi'};
    }
    // Hapus validasi email (tidak perlu mengandung '@')
    if (password.length < 6) {
      return {'success': false, 'message': 'Password minimal 6 karakter'};
    }
    if (password != confirmPassword) {
      return {'success': false, 'message': 'Password dan konfirmasi password tidak sama'};
    }

    try {
      return await finalizeSignup({
        'name': name,
        'email': email,
        'password': password,
      });
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
        return {'success': false, 'message': 'Username sudah digunakan'};
      }
      if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'Format username tidak valid (jangan gunakan karakter aneh)'};
      }
      return {'success': false, 'message': e.message ?? 'Gagal mendaftar'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem'};
    }

    return {'success': false, 'message': 'Registrasi gagal'};
  }
}