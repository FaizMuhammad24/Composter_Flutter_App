import '../../models/user_model.dart';
import '../database/fake_database.dart';
import '../auth/password_service.dart';

class AdminService {

  // ==================== CREATE ADMIN ====================
  static Future<Map<String, dynamic>> createAdminBySuperAdmin({
    required String superAdminEmail,
    required String name,
    required String email,
    required String password,
  }) async {

    await Future.delayed(const Duration(seconds: 1));

    email = email.toLowerCase().trim();
    superAdminEmail = superAdminEmail.toLowerCase().trim();

    // Validasi Super Admin
    if (!FakeDatabase.users.containsKey(superAdminEmail)) {
      return {
        'success': false,
        'message': 'Super Admin tidak ditemukan',
      };
    }

    var superAdmin = FakeDatabase.users[superAdminEmail]!;

    if (superAdmin['role'] != 'super_admin') {
      return {
        'success': false,
        'message': 'Hanya Super Admin yang bisa membuat admin',
      };
    }

    // Validasi input
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Semua field harus diisi',
      };
    }

    if (!email.contains('@')) {
      return {
        'success': false,
        'message': 'Format email tidak valid',
      };
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password minimal 6 karakter',
      };
    }

    if (FakeDatabase.users.containsKey(email)) {
      return {
        'success': false,
        'message': 'Email sudah terdaftar',
      };
    }

    // Membuat admin baru
    var newAdmin = {
      'uid': 'admin_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'email': email,
      'password': PasswordService.hashPassword(password),
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
      'created_by': superAdminEmail,
    };

    FakeDatabase.users[email] = newAdmin;

    return {
      'success': true,
      'message': 'Admin berhasil dibuat',
      'user': UserModel.fromJson(newAdmin),
    };
  }

  // ==================== GET ALL ADMINS ====================
  static Future<List<UserModel>> getAllAdmins() async {

    await Future.delayed(const Duration(milliseconds: 500));

    return FakeDatabase.users.values
        .where((user) => user['role'] == 'admin')
        .map((user) => UserModel.fromJson(user))
        .toList();
  }

  // ==================== DELETE ADMIN ====================
  static Future<Map<String, dynamic>> deleteAdmin({
    required String superAdminEmail,
    required String adminUid,
  }) async {

    await Future.delayed(const Duration(milliseconds: 500));

    superAdminEmail = superAdminEmail.toLowerCase().trim();

    // Validasi Super Admin
    if (!FakeDatabase.users.containsKey(superAdminEmail)) {
      return {
        'success': false,
        'message': 'Super Admin tidak ditemukan',
      };
    }

    var superAdmin = FakeDatabase.users[superAdminEmail]!;

    if (superAdmin['role'] != 'super_admin') {
      return {
        'success': false,
        'message': 'Hanya Super Admin yang bisa menghapus admin',
      };
    }

    bool deleted = false;

    FakeDatabase.users.removeWhere((key, value) {
      if (value['uid'] == adminUid && value['role'] == 'admin') {
        deleted = true;
        return true;
      }
      return false;
    });

    if (deleted) {
      return {
        'success': true,
        'message': 'Admin berhasil dihapus',
      };
    }

    return {
      'success': false,
      'message': 'Admin tidak ditemukan',
    };
  }
}