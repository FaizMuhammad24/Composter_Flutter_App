import '../../models/user_model.dart';
import '../database/fake_database.dart';
import 'password_service.dart';

class SignupService {

  static Future<Map<String, dynamic>> signUpUser({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {

    await Future.delayed(const Duration(seconds: 1));

    email = email.toLowerCase().trim();

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

    if (password != confirmPassword) {
      return {
        'success': false,
        'message': 'Password dan konfirmasi password tidak sama',
      };
    }

    if (FakeDatabase.users.containsKey(email)) {
      return {
        'success': false,
        'message': 'Email sudah terdaftar',
      };
    }

    var newUser = {
      'uid': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'email': email,
      'password': PasswordService.hashPassword(password),
      'role': 'user',
      'points': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    FakeDatabase.users[email] = newUser;

    return {
      'success': true,
      'message': 'Registrasi berhasil',
      'user': UserModel.fromJson(newUser),
    };
  }

}