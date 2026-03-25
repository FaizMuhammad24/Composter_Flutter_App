import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AdminService {

  static Future<Map<String, dynamic>> createAdminBySuperAdmin({
    required String superAdminEmail,
    required String name,
    required String email,
    required String password,
  }) async {
    email = email.toLowerCase().trim();
    superAdminEmail = superAdminEmail.toLowerCase().trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) return {'success': false, 'message': 'Semua field harus diisi'};
    if (!email.contains('@')) return {'success': false, 'message': 'Format email tidak valid'};
    if (password.length < 6) return {'success': false, 'message': 'Password minimal 6 karakter'};

    try {
      var superSnap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: superAdminEmail).limit(1).get();
      if (superSnap.docs.isEmpty || (superSnap.docs.first.data()['role'] != 'super_admin' && superSnap.docs.first.data()['role'] != 'superadmin')) {
        return {'success': false, 'message': 'Hanya Super Admin yang bisa membuat admin'};
      }

      var existing = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (existing.docs.isNotEmpty) { return {'success': false, 'message': 'Email sudah terdaftar di Firestore'}; }

      // TRICK: Gunakan Secondary App agar tidak melogout-kan akun Super Admin dari sesi utama
      FirebaseApp app = await Firebase.initializeApp(name: 'SecondaryApp', options: Firebase.app().options);
      try {
        UserCredential cred = await FirebaseAuth.instanceFor(app: app).createUserWithEmailAndPassword(email: email, password: password);
        String uid = cred.user!.uid;

        var newAdmin = {
          'uid': uid,
          'name': name,
          'email': email,
          'role': 'admin',
          'points': null,
          'created_at': DateTime.now().toIso8601String(),
          'created_by': superAdminEmail,
        };

        await FirebaseFirestore.instance.collection('users').doc(uid).set(newAdmin);

        return {'success': true, 'message': 'Admin berhasil dibuat', 'user': UserModel.fromJson(newAdmin)};
      } finally {
        await app.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') { return {'success': false, 'message': 'Email sudah terdaftar di Sistem'}; }
      return {'success': false, 'message': 'Error Firebase Auth: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat admin: $e'};
    }
  }

  static Future<List<UserModel>> getAllAdmins() async {
    var snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').get();
    return snap.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  static Future<Map<String, dynamic>> deleteAdmin({
    required String superAdminEmail,
    required String adminUid,
  }) async {
    superAdminEmail = superAdminEmail.toLowerCase().trim();
    try {
      var superSnap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: superAdminEmail).limit(1).get();
      if (superSnap.docs.isEmpty || (superSnap.docs.first.data()['role'] != 'super_admin' && superSnap.docs.first.data()['role'] != 'superadmin')) {
        return {'success': false, 'message': 'Hanya Super Admin yang bisa menghapus admin'};
      }

      var targetSnap = await FirebaseFirestore.instance.collection('users').doc(adminUid).get();
      if (targetSnap.exists && targetSnap.data()?['role'] == 'admin') {
        await FirebaseFirestore.instance.collection('users').doc(adminUid).delete();
        return {'success': true, 'message': 'Admin berhasil dihapus (Sistem)'};
      }
      return {'success': false, 'message': 'Admin tidak ditemukan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus admin'};
    }
  }
}