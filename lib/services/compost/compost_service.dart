import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/compost_model.dart';
import '../user/points_service.dart';

class CompostService {

  static int calculatePoints(double weight) {
    // 1 kg = 10 points
    return (weight * 10).toInt();
  }

  static Future<Map<String, dynamic>> addCompost({
    required String userEmail,
    required double weight,
    required String imageUrl,
  }) async {

    try {
      var users = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();
      if (users.docs.isEmpty) {
        return {'success': false, 'message': 'User tidak ditemukan'};
      }
      
      int points = calculatePoints(weight);

      var compostRef = FirebaseFirestore.instance.collection('composts').doc();
      var compost = {
        'id': compostRef.id,
        'userEmail': userEmail,
        'weight': weight,
        'points': points,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      };
      
      await compostRef.set(compost);
      await PointsService.addUserPoints(userEmail: userEmail, pointsToAdd: points);

      return {
        'success': true,
        'message': 'Setoran kompos berhasil',
        'data': CompostModel.fromJson(compost),
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal menyimpan data'};
    }
  }

  static Future<List<CompostModel>> getUserComposts(String email) async {
    var snap = await FirebaseFirestore.instance.collection('composts')
      .where('userEmail', isEqualTo: email)
      .orderBy('createdAt', descending: true)
      .get();
    return snap.docs.map((doc) => CompostModel.fromJson(doc.data())).toList();
  }

  static Future<List<CompostModel>> getAllComposts() async {
    var snap = await FirebaseFirestore.instance.collection('composts')
      .orderBy('createdAt', descending: true)
      .get();
    return snap.docs.map((doc) => CompostModel.fromJson(doc.data())).toList();
  }

}