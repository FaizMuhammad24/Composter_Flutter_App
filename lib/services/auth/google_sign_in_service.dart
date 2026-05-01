import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import 'session_service.dart';

class GoogleSignInService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  /// Masuk dengan akun Google.
  /// Jika user baru, profil dibuat otomatis dengan role 'user'.
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Paksa pilih akun agar tidak auto-login dengan akun terakhir
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User menekan tombol "Batal"
        return {'success': false, 'message': 'Login dibatalkan'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {'success': false, 'message': 'Gagal mendapatkan data pengguna'};
      }

      final String uid = firebaseUser.uid;
      final String email = firebaseUser.email ?? '';
      final String name = firebaseUser.displayName ?? email.split('@').first;

      // Cek apakah profil sudah ada di Firestore
      final docRef = _firestore.collection('users').doc(uid);
      final docSnap = await docRef.get();

      UserModel user;
      if (!docSnap.exists) {
        // User baru — buat profil dengan role 'user'
        final newUserData = {
          'uid': uid,
          'name': name,
          'email': email,
          'role': 'user',
          'points': 0,
          'photo_url': firebaseUser.photoURL ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'auth_provider': 'google',
        };
        await docRef.set(newUserData);
        user = UserModel.fromJson(newUserData);
      } else {
        // User lama — load profil dari Firestore
        final data = docSnap.data()!;
        user = UserModel.fromJson(data);
        // Update last_login
        await docRef.update({'last_login': DateTime.now().toIso8601String()});
      }

      await SessionService.setCurrentUser(user);
      return {'success': true, 'message': 'Login berhasil', 'user': user};
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan saat login dengan Google'};
    }
  }
}
