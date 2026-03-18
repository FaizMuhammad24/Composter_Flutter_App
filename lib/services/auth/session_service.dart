import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../database/fake_database.dart';

class SessionService {

  static UserModel? _currentUser;
  static const String _sessionKey = 'user_session';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString(_sessionKey);
    
    if (sessionData != null) {
      final Map<String, dynamic> userMap = json.decode(sessionData);
      // Validasi ulang dengan database (simulasi)
      final email = userMap['email'];
      if (FakeDatabase.users.containsKey(email)) {
        _currentUser = UserModel.fromJson(FakeDatabase.users[email]!);
      }
    }
  }

  static Future<void> setCurrentUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, json.encode(user.toJson()));
  }

  static UserModel? getCurrentUser() {
    return _currentUser;
  }

  static bool isLoggedIn() {
    return _currentUser != null;
  }

  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

}