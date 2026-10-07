import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'session_service.dart';

class LoginService {

  static Future<Map<String, dynamic>> login(
      String username,
      String password,
  ) async {
    // Bersihkan input
    username = username.toLowerCase().replaceAll(RegExp(r'[\s@]+'), '').trim();
    final String email = '$username@icompost.app';

    if (username.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Username dan password tidak boleh kosong',
      };
    }

    try {
      // Login melalui Firebase Auth
      final UserCredential cred =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user == null) {
        return {'success': false, 'message': 'Login gagal, silakan coba lagi'};
      }

      final String uid = cred.user!.uid;

      // Ambil data profil dari Firestore berdasarkan UID
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        // Profil ditemukan → muat data user
        UserModel user = UserModel.fromJson(doc.data()!);
        user = user.copyWith(lastLogin: DateTime.now());

        // Update last_login di Firestore (non-blocking)
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'last_login': user.lastLogin?.toIso8601String(),
        }).catchError((_) {});

        await SessionService.setCurrentUser(user);
        return {'success': true, 'message': 'Login berhasil', 'user': user};
      }

      // Profil belum ada di UID → cari berdasarkan email (migrasi data lama)
      final QuerySnapshot<Map<String, dynamic>> emailQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (emailQuery.docs.isNotEmpty) {
        final oldDoc = emailQuery.docs.first;
        final Map<String, dynamic> userData = Map.from(oldDoc.data());
        userData['uid'] = uid;

        // Migrasi: simpan ke doc baru dengan UID Auth, hapus doc lama
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);
        if (oldDoc.id != uid) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(oldDoc.id)
              .delete();
        }

        UserModel user = UserModel.fromJson(userData);
        user = user.copyWith(lastLogin: DateTime.now());

        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'last_login': user.lastLogin?.toIso8601String(),
        }).catchError((_) {});

        await SessionService.setCurrentUser(user);
        return {
          'success': true,
          'message': 'Login berhasil',
          'user': user,
        };
      }

      // Tidak ada data profil sama sekali
      return {
        'success': false,
        'message': 'Data profil tidak ditemukan di sistem',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return {'success': false, 'message': 'Username atau password salah'};
      }
      if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'Format username tidak valid'};
      }
      if (e.code == 'too-many-requests') {
        return {
          'success': false,
          'message': 'Terlalu banyak percobaan. Coba lagi nanti.',
        };
      }
      return {'success': false, 'message': e.message ?? 'Gagal login'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}