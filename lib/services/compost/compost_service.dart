import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/compost_model.dart';
import '../notifications/user_notification_service.dart';

class CompostService {

  static int calculatePoints(double weight) {
    final int pointsPerKg = int.tryParse(dotenv.env['POINTS_PER_KG'] ?? '10') ?? 10;
    return (weight * pointsPerKg).toInt();
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

      // Notify user via UserNotificationService (which translates to firestore doc and local push)
      try {
        await UserNotificationService.notifyDepositPending(userEmail, weight);
      } catch (e) {
        // ignore errors
      }

      // Poin HANYA ditambahkan setelah Admin menyetujui (ACC)
      // PointsService.addUserPoints dipanggil di Admin approval logic

      return {
        'success': true,
        'message': 'Setoran berhasil diajukan! Menunggu persetujuan Admin.',
        'data': CompostModel.fromJson(compost),
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal menyimpan data'};
    }
  }

  static Future<List<CompostModel>> getUserComposts(String email) async {
    var snap = await FirebaseFirestore.instance.collection('composts')
      .where('userEmail', isEqualTo: email)
      .get();
      
    var list = snap.docs.map((doc) => CompostModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<List<CompostModel>> getAllComposts() async {
    var snap = await FirebaseFirestore.instance.collection('composts')
      .orderBy('createdAt', descending: true)
      .get();
    return snap.docs.map((doc) => CompostModel.fromJson(doc.data())).toList();
  }

  static Future<void> updateCompostStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('composts').doc(id).update({
      'status': status,
    });
  }

}