import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class PointsService {

  static Future<Map<String, dynamic>> updateUserPoints({
    required String userEmail,
    required int points,
  }) async {
    userEmail = userEmail.toLowerCase().trim();
    var snap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();
    
    if (snap.docs.isEmpty) { return {'success': false, 'message': 'User tidak ditemukan'}; }
    
    var doc = snap.docs.first;
    if (doc.data()['role'] != 'user') { return {'success': false, 'message': 'Hanya user yang memiliki poin'}; }
    
    await FirebaseFirestore.instance.collection('users').doc(doc.id).update({'points': points});
    var updatedDoc = await FirebaseFirestore.instance.collection('users').doc(doc.id).get();
    
    return {
      'success': true,
      'message': 'Poin berhasil diupdate',
      'user': UserModel.fromJson(updatedDoc.data()!),
    };
  }

  static Future<Map<String, dynamic>> addUserPoints({
    required String userEmail,
    required int pointsToAdd,
  }) async {
    userEmail = userEmail.toLowerCase().trim();
    var snap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();
    
    if (snap.docs.isEmpty) { return {'success': false, 'message': 'User tidak ditemukan'}; }
    
    var doc = snap.docs.first;
    if (doc.data()['role'] != 'user') { return {'success': false, 'message': 'Hanya user yang memiliki poin'}; }
    
    int currentPoints = doc.data()['points'] ?? 0;
    int newPoints = currentPoints + pointsToAdd;
    
    await FirebaseFirestore.instance.collection('users').doc(doc.id).update({'points': newPoints});
    var updatedDoc = await FirebaseFirestore.instance.collection('users').doc(doc.id).get();
    
    return {
      'success': true,
      'message': 'Poin berhasil ditambahkan',
      'points': newPoints,
      'user': UserModel.fromJson(updatedDoc.data()!),
    };
  }

  /// Kurangi poin user (digunakan saat klaim reward disetujui)
  static Future<Map<String, dynamic>> deductUserPoints({
    required String userEmail,
    required int pointsToDeduct,
  }) async {
    userEmail = userEmail.toLowerCase().trim();
    var snap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();
    
    if (snap.docs.isEmpty) { return {'success': false, 'message': 'User tidak ditemukan'}; }
    
    var doc = snap.docs.first;
    if (doc.data()['role'] != 'user') { return {'success': false, 'message': 'Hanya user yang memiliki poin'}; }
    
    int currentPoints = doc.data()['points'] ?? 0;
    int newPoints = (currentPoints - pointsToDeduct).clamp(0, currentPoints);
    
    await FirebaseFirestore.instance.collection('users').doc(doc.id).update({'points': newPoints});
    var updatedDoc = await FirebaseFirestore.instance.collection('users').doc(doc.id).get();
    
    return {
      'success': true,
      'message': 'Poin berhasil dikurangi',
      'points': newPoints,
      'user': UserModel.fromJson(updatedDoc.data()!),
    };
  }

}