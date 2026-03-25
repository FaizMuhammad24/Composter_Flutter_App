import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/compost_model.dart';

class HistoryService {

  static Future<List<CompostModel>> getUserHistory(String userEmail) async {
    var snap = await FirebaseFirestore.instance.collection('composts')
      .where('userEmail', isEqualTo: userEmail)
      .orderBy('createdAt', descending: true)
      .get();
    return snap.docs.map((c) => CompostModel.fromJson(c.data())).toList();
  }

  static Future<List<CompostModel>> getAllHistory() async {
    var snap = await FirebaseFirestore.instance.collection('composts')
      .orderBy('createdAt', descending: true)
      .get();
    return snap.docs.map((c) => CompostModel.fromJson(c.data())).toList();
  }

  static Future<List<CompostModel>> getRecentTransactions({int limit = 5}) async {
    var snap = await FirebaseFirestore.instance.collection('composts')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .get();
    return snap.docs.map((c) => CompostModel.fromJson(c.data())).toList();
  }
}