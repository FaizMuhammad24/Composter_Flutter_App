import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/compost_model.dart';

class DashboardService {

  static Future<int> getTotalUsers() async {
    var snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').count().get();
    return snap.count ?? 0;
  }

  static Future<int> getTotalAdmins() async {
    var snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').count().get();
    return snap.count ?? 0;
  }

  static Future<int> getTotalComposts() async {
    var snap = await FirebaseFirestore.instance.collection('composts').count().get();
    return snap.count ?? 0;
  }

  static Future<int> getTotalPoints() async {
    var snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').get();
    int total = 0;
    for (var doc in snap.docs) {
      total += (doc.data()['points'] ?? 0) as int;
    }
    return total;
  }

  static Future<List<CompostModel>> getRecentTransactions({int limit = 5}) async {
    var snap = await FirebaseFirestore.instance.collection('composts').orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map((doc) => CompostModel.fromJson(doc.data())).toList();
  }
  
}