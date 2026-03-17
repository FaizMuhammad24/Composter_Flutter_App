import 'login_service.dart';
import 'signup_service.dart';

class AuthService {

  static Future<Map<String, dynamic>> login(
      String email,
      String password
  ) {
    return LoginService.login(email, password);
  }

  static Future<Map<String, dynamic>> signUpUser({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {

    return SignupService.signUpUser(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

  }

}