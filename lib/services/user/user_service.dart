import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class UserService {

  static Future<List<UserModel>> getAllUsers() async {
    var snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').get();
    return snap.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    email = email.toLowerCase().trim();
    var snap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return UserModel.fromJson(snap.docs.first.data());
    }
    return null;
  }

  static Future<Map<String, dynamic>> deleteUser(String userUid) async {
    try {
      var snap = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
      if (snap.exists && snap.data()?['role'] == 'user') {
        await FirebaseFirestore.instance.collection('users').doc(userUid).delete();
        return {'success': true, 'message': 'User berhasil dihapus (Note: Firebase Auth record remains)'};
      }
      return {'success': false, 'message': 'User tidak ditemukan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus user'};
    }
  }

}