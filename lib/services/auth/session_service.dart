import '../../models/user_model.dart';

class SessionService {

  static UserModel? _currentUser;

  static void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  static UserModel? getCurrentUser() {
    return _currentUser;
  }

  static bool isLoggedIn() {
    return _currentUser != null;
  }

  static void logout() {
    _currentUser = null;
  }

}