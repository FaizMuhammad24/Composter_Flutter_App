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
    try {
      userEmail = userEmail.toLowerCase().trim();
      var snap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();
      
      if (snap.docs.isEmpty) { return {'success': false, 'message': 'User tidak ditemukan'}; }
      
      var docRef = FirebaseFirestore.instance.collection('users').doc(snap.docs.first.id);
      
      var result = await FirebaseFirestore.instance.runTransaction((transaction) async {
        var snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) { throw Exception('User document not found'); }
        if (snapshot.data()?['role'] != 'user') { throw Exception('Hanya user yang memiliki poin'); }
        
        int currentPoints = snapshot.data()?['points'] ?? 0;
        int newPoints = currentPoints + pointsToAdd;
        
        transaction.update(docRef, {'points': newPoints});
        
        var updatedData = snapshot.data()!;
        updatedData['points'] = newPoints;
        return updatedData;
      });
      
      return {
        'success': true,
        'message': 'Poin berhasil ditambahkan',
        'points': result['points'],
        'user': UserModel.fromJson(result),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  /// Kurangi poin user (digunakan saat klaim reward disetujui)
  static Future<Map<String, dynamic>> deductUserPoints({
    required String userEmail,
    required int pointsToDeduct,
  }) async {
    try {
      userEmail = userEmail.toLowerCase().trim();
      var snap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();
      
      if (snap.docs.isEmpty) { return {'success': false, 'message': 'User tidak ditemukan'}; }
      
      var docRef = FirebaseFirestore.instance.collection('users').doc(snap.docs.first.id);
      
      var result = await FirebaseFirestore.instance.runTransaction((transaction) async {
        var snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) { throw Exception('User document not found'); }
        if (snapshot.data()?['role'] != 'user') { throw Exception('Hanya user yang memiliki poin'); }
        
        int currentPoints = snapshot.data()?['points'] ?? 0;
        int newPoints = (currentPoints - pointsToDeduct).clamp(0, currentPoints);
        
        transaction.update(docRef, {'points': newPoints});
        
        var updatedData = snapshot.data()!;
        updatedData['points'] = newPoints;
        return updatedData;
      });
      
      return {
        'success': true,
        'message': 'Poin berhasil dikurangi',
        'points': result['points'],
        'user': UserModel.fromJson(result),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

}