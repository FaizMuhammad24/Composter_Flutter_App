import '../../models/compost_model.dart';
import '../database/fake_database.dart';
import '../user/points_service.dart';

class CompostService {

  // ==================== CALCULATE POINTS ====================
  static int calculatePoints(double weight) {

    // contoh konversi
    // 1 kg = 10 poin

    return (weight * 10).toInt();
  }

  // ==================== ADD COMPOST ====================
  static Future<Map<String, dynamic>> addCompost({
    required String userEmail,
    required String wasteType,
    required double weight,
  }) async {

    await Future.delayed(const Duration(milliseconds: 500));

    if (!FakeDatabase.users.containsKey(userEmail)) {
      return {
        'success': false,
        'message': 'User tidak ditemukan'
      };
    }

    int points = calculatePoints(weight);

    var compost = {
      'id': 'compost_${DateTime.now().millisecondsSinceEpoch}',
      'userEmail': userEmail,
      'wasteType': wasteType,
      'weight': weight,
      'points': points,
      'createdAt': DateTime.now().toIso8601String(),
    };

    FakeDatabase.composts.add(compost);

    // tambahkan poin ke user
    await PointsService.addUserPoints(
      userEmail: userEmail,
      pointsToAdd: points,
    );

    return {
      'success': true,
      'message': 'Setoran kompos berhasil',
      'data': CompostModel.fromJson(compost),
    };
  }

  // ==================== GET USER COMPOSTS ====================
  static Future<List<CompostModel>> getUserComposts(String email) async {

    await Future.delayed(const Duration(milliseconds: 300));

    return FakeDatabase.composts
        .where((c) => c['userEmail'] == email)
        .map((c) => CompostModel.fromJson(c))
        .toList();
  }

  // ==================== GET ALL COMPOSTS ====================
  static Future<List<CompostModel>> getAllComposts() async {

    await Future.delayed(const Duration(milliseconds: 300));

    return FakeDatabase.composts
        .map((c) => CompostModel.fromJson(c))
        .toList();
  }

}