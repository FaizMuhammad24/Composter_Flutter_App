import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'package:flutter/foundation.dart';

class AdminService {

  static Future<List<UserModel>> getAllAdmins() async {
    var snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').get();
    return snap.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  static Future<Map<String, dynamic>> deleteAdmin({
    required String adminUid,
  }) async {
    try {
      var targetSnap = await FirebaseFirestore.instance.collection('users').doc(adminUid).get();
      if (targetSnap.exists && targetSnap.data()?['role'] == 'admin') {
        final data = targetSnap.data()!;
        final email = data['email']?.toString() ?? '';
        final authEmail = data['auth_email']?.toString() ?? email;
        final pass = data['auth_pass']?.toString();

        // 1. Coba hapus akun dari Firebase Authentication jika credential tersedia
        if (authEmail.isNotEmpty && pass != null && pass.isNotEmpty) {
          try {
            FirebaseApp app = await Firebase.initializeApp(
              name: 'DeleteAdmin_${DateTime.now().millisecondsSinceEpoch}',
              options: Firebase.app().options,
            );
            try {
              UserCredential cred = await FirebaseAuth.instanceFor(app: app)
                  .signInWithEmailAndPassword(email: authEmail, password: pass);
              await cred.user?.delete();
            } catch (authErr) {
              debugPrint('Error deleting auth user: $authErr');
            } finally {
              await app.delete();
            }
          } catch (e) {
            debugPrint('Error init secondary app for delete: $e');
          }
        }

        // 2. Hapus dokumen dari Firestore
        await FirebaseFirestore.instance.collection('users').doc(adminUid).delete();
        return {'success': true, 'message': 'Admin berhasil dihapus'};
      }
      return {'success': false, 'message': 'Admin tidak ditemukan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus admin: $e'};
    }
  }

  static Future<Map<String, dynamic>> createAdmin({
    required String name,
    required String username,
    required String password,
  }) async {
    // Sanitasi username: lowercase, hapus spasi & @
    username = username.toLowerCase().replaceAll(RegExp(r'[\s@]+'), '').trim();
    final email = '$username@icompost.app';

    // Validasi input
    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Semua field harus diisi'};
    }
    if (password.length < 6) {
      return {'success': false, 'message': 'Password minimal 6 karakter'};
    }

    try {
      // Cek apakah username sudah terdaftar di Firestore
      var existing = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return {'success': false, 'message': 'Username sudah digunakan'};
      }

      String targetAuthEmail = email;

      FirebaseApp app = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      try {
        UserCredential cred;
        try {
          cred = await FirebaseAuth.instanceFor(app: app)
              .createUserWithEmailAndPassword(
                email: targetAuthEmail,
                password: password,
              );
        } on FirebaseAuthException catch (authErr) {
          if (authErr.code == 'email-already-in-use') {
            // Dokumen di Firestore sudah terhapus, tetapi Firebase Auth record masih ada.
            // Coba login & gunakan akun Auth lama jika password cocok.
            try {
              cred = await FirebaseAuth.instanceFor(app: app)
                  .signInWithEmailAndPassword(email: targetAuthEmail, password: password);
            } catch (_) {
              // Jika login gagal (password lama beda), buat Auth email unik internal
              targetAuthEmail = '${username}_${DateTime.now().millisecondsSinceEpoch}@icompost.app';
              cred = await FirebaseAuth.instanceFor(app: app)
                  .createUserWithEmailAndPassword(email: targetAuthEmail, password: password);
            }
          } else {
            rethrow;
          }
        }

        String uid = cred.user!.uid;

        Map<String, dynamic> newAdmin = {
          'uid': uid,
          'name': name,
          'email': email,
          'auth_email': targetAuthEmail,
          'auth_pass': password,
          'role': 'admin',
          'points': null,
          'created_at': DateTime.now().toIso8601String(),
        };

        await FirebaseFirestore.instance.collection('users').doc(uid).set(newAdmin);

        return {
          'success': true,
          'message': 'Admin berhasil dibuat',
          'user': UserModel.fromJson(newAdmin),
        };
      } finally {
        await app.delete(); // Hapus instance secondary app
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'Format username tidak valid'};
      }
      return {'success': false, 'message': 'Error Auth: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat admin: $e'};
    }
  }
}