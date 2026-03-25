import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class SessionService {

  static UserModel? _currentUser;
  static const String _sessionKey = 'user_session';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString(_sessionKey);
    
    if (sessionData != null) {
      final Map<String, dynamic> userMap = json.decode(sessionData);
      _currentUser = UserModel.fromJson(userMap);

      // Sinkronisasi dengan Firestore jika user masih login di Firebase Auth
      var fUser = FirebaseAuth.instance.currentUser;
      if (fUser != null) {
        try {
          var doc = await FirebaseFirestore.instance.collection('users').doc(fUser.uid).get();
          if (doc.exists) {
            _currentUser = UserModel.fromJson(doc.data()!);
            await setCurrentUser(_currentUser!);
          }
        } catch (e) {
          // Abaikan jika offline
        }
      } else {
        await logout();
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
    return _currentUser != null && FirebaseAuth.instance.currentUser != null;
  }

  static Future<void> logout() async {
    _currentUser = null;
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

}