import '../../models/user_model.dart';
import '../database/fake_database.dart';

class PointsService {

  // ==================== UPDATE USER POINTS ====================
  static Future<Map<String, dynamic>> updateUserPoints({
    required String userEmail,
    required int points,
  }) async {

    await Future.delayed(const Duration(milliseconds: 300));

    userEmail = userEmail.toLowerCase().trim();

    if (!FakeDatabase.users.containsKey(userEmail)) {
      return {
        'success': false,
        'message': 'User tidak ditemukan',
      };
    }

    var user = FakeDatabase.users[userEmail]!;

    if (user['role'] != 'user') {
      return {
        'success': false,
        'message': 'Hanya user yang memiliki poin',
      };
    }

    user['points'] = points;

    return {
      'success': true,
      'message': 'Poin berhasil diupdate',
      'user': UserModel.fromJson(user),
    };
  }

  // ==================== ADD USER POINTS ====================
  static Future<Map<String, dynamic>> addUserPoints({
    required String userEmail,
    required int pointsToAdd,
  }) async {

    await Future.delayed(const Duration(milliseconds: 300));

    userEmail = userEmail.toLowerCase().trim();

    if (!FakeDatabase.users.containsKey(userEmail)) {
      return {
        'success': false,
        'message': 'User tidak ditemukan',
      };
    }

    var user = FakeDatabase.users[userEmail]!;

    if (user['role'] != 'user') {
      return {
        'success': false,
        'message': 'Hanya user yang memiliki poin',
      };
    }

    int currentPoints = user['points'] ?? 0;

    user['points'] = currentPoints + pointsToAdd;

    return {
      'success': true,
      'message': 'Poin berhasil ditambahkan',
      'points': user['points'],
      'user': UserModel.fromJson(user),
    };
  }

}