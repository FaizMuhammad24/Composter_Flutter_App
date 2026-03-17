import '../../models/user_model.dart';
import '../database/fake_database.dart';

class UserService {

  // ==================== GET ALL USERS ====================
  static Future<List<UserModel>> getAllUsers() async {

    await Future.delayed(const Duration(milliseconds: 500));

    return FakeDatabase.users.values
        .where((user) => user['role'] == 'user')
        .map((user) => UserModel.fromJson(user))
        .toList();
  }

  // ==================== GET USER BY EMAIL ====================
  static Future<UserModel?> getUserByEmail(String email) async {

    await Future.delayed(const Duration(milliseconds: 300));

    email = email.toLowerCase().trim();

    if (FakeDatabase.users.containsKey(email)) {
      return UserModel.fromJson(FakeDatabase.users[email]!);
    }

    return null;
  }

  // ==================== DELETE USER ====================
  static Future<Map<String, dynamic>> deleteUser(String userUid) async {

    await Future.delayed(const Duration(milliseconds: 500));

    bool deleted = false;

    FakeDatabase.users.removeWhere((key, value) {
      if (value['uid'] == userUid && value['role'] == 'user') {
        deleted = true;
        return true;
      }
      return false;
    });

    if (deleted) {
      return {
        'success': true,
        'message': 'User berhasil dihapus',
      };
    } else {
      return {
        'success': false,
        'message': 'User tidak ditemukan',
      };
    }
  }

}