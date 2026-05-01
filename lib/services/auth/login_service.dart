import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'session_service.dart';

class LoginService {

  static Future<Map<String, dynamic>> login(
      String email,
      String password
  ) async {

    email = email.toLowerCase().trim();

    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Email dan password tidak boleh kosong',
      };
    }

    try {
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // Cek apakah email sudah diverifikasi
        // Pengecualian untuk admin dan super_admin (yang dibuat manual)
        final bool isEmailVerified = cred.user!.emailVerified;

        var doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        if (doc.exists) {
          var userData = doc.data()!;
          var user = UserModel.fromJson(userData);

          // Blokir login jika email belum diverifikasi (khusus role 'user')
          if (!isEmailVerified && user.role == 'user') {
            await FirebaseAuth.instance.signOut();
            return {
              'success': false,
              'message': 'Email Anda belum diverifikasi. Silakan cek kotak masuk email dan klik link verifikasi yang telah dikirimkan.',
              'needsVerification': true,
              'email': email,
            };
          }

          // Update last_login
          user = user.copyWith(lastLogin: DateTime.now());
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).update({
            'last_login': user.lastLogin?.toIso8601String()
          });
          
          await SessionService.setCurrentUser(user);
          return {'success': true, 'message': 'Login berhasil', 'user': user};
        } else {
          return {'success': false, 'message': 'Data profil tidak ditemukan di sistem'};
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return {'success': false, 'message': 'Email atau password salah'};
      }
      return {'success': false, 'message': e.message ?? 'Gagal login'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem'};
    }

    return {'success': false, 'message': 'Gagal login'};
  }

}