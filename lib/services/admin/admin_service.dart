import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

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
        await FirebaseFirestore.instance.collection('users').doc(adminUid).delete();
        return {'success': true, 'message': 'Admin berhasil dihapus'};
      }
      return {'success': false, 'message': 'Admin tidak ditemukan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus admin'};
    }
  }

  static Future<Map<String, dynamic>> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    // Validasi input
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return {'success': false, 'message': 'Semua field harus diisi'};
    }
    if (!email.contains('@')) {
      return {'success': false, 'message': 'Format email tidak valid'};
    }
    if (password.length < 6) {
      return {'success': false, 'message': 'Password minimal 6 karakter'};
    }

    try {
      // Cek apakah email sudah terdaftar di Firestore
      var existing = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return {'success': false, 'message': 'Email sudah terdaftar'};
      }

      // GUNAKAN SECONDARY APP agar admin utama tidak logout
      FirebaseApp app = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      try {
        UserCredential cred = await FirebaseAuth.instanceFor(app: app)
            .createUserWithEmailAndPassword(
              email: email.toLowerCase().trim(),
              password: password,
            );

        String uid = cred.user!.uid;

        Map<String, dynamic> newAdmin = {
          'uid': uid,
          'name': name,
          'email': email.toLowerCase().trim(),
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
      if (e.code == 'email-already-in-use') {
        return {'success': false, 'message': 'Email sudah terdaftar di sistem'};
      }
      return {'success': false, 'message': 'Error Auth: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat admin: $e'};
    }
  }
}