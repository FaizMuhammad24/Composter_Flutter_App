import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/compost_model.dart';

class CompostService {

  static int calculatePoints(double weight) {
    final int pointsPerKg = int.tryParse(dotenv.env['POINTS_PER_KG'] ?? '10') ?? 10;
    return (weight * pointsPerKg).toInt();
  }

  static Future<Map<String, dynamic>> addCompost({
    required String userEmail,
    required double weight,
    required String imageUrl,
    DateTime? customDate,
  }) async {

    try {
      var users = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();
      if (users.docs.isEmpty) {
        return {'success': false, 'message': 'User tidak ditemukan'};
      }
      
      final userData = users.docs.first.data();
      final String userName = userData['name']?.toString() ?? (userEmail.contains('@') ? userEmail.split('@').first : userEmail);

      int points = calculatePoints(weight);

      var compostRef = FirebaseFirestore.instance.collection('composts').doc();
      final String createdAtStr = (customDate ?? DateTime.now()).toIso8601String();
      
      var compost = {
        'id': compostRef.id,
        'userEmail': userEmail,
        'userName': userName,
        'weight': weight,
        'points': points,
        'imageUrl': imageUrl,
        'createdAt': createdAtStr,
        'status': 'pending',
      };
      
      await compostRef.set(compost);

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