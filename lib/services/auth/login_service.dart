import '../../models/user_model.dart';
import '../database/fake_database.dart';
import 'password_service.dart';
import 'session_service.dart';

class LoginService {

  static Future<Map<String, dynamic>> login(
      String email,
      String password
  ) async {

    await Future.delayed(const Duration(seconds: 1));

    email = email.toLowerCase().trim();

    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Email dan password tidak boleh kosong',
      };
    }

    if (!FakeDatabase.users.containsKey(email)) {
      return {
        'success': false,
        'message': 'Email tidak terdaftar',
      };
    }

    var userData = FakeDatabase.users[email]!;

    String hashedPassword = PasswordService.hashPassword(password);

    if (userData['password'] != hashedPassword) {
      return {
        'success': false,
        'message': 'Password salah',
      };
    }

    userData['last_login'] = DateTime.now().toIso8601String();

    var user = UserModel.fromJson(userData);

    await SessionService.setCurrentUser(user);

    return {
      'success': true,
      'message': 'Login berhasil',
      'user': user,
    };
  }

}