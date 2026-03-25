import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_notification_model.dart';
import 'package:flutter/foundation.dart';

class AppNotificationService {
  static final _notificationsCol = FirebaseFirestore.instance.collection('notifications');

  /// Mendapatkan stream notifikasi untuk user tertentu
  static Stream<List<AppNotificationModel>> getUserNotificationsStream(String email) {
    return _notificationsCol
        .where('userEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotificationModel.fromJson(doc.data()))
            .toList());
  }

  /// Mendapatkan jumlah notifikasi yang belum dibaca
  static Stream<int> getUnreadCountStream(String email) {
    return _notificationsCol
        .where('userEmail', isEqualTo: email)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Membuat notifikasi baru (Bisa dipanggil dari sisi User/Admin)
  static Future<void> createNotification({
    required String userEmail,
    required String title,
    required String message,
    required String type, // 'success', 'error', 'reward', 'system'
  }) async {
    try {
      final id = _notificationsCol.doc().id;
      final notification = AppNotificationModel(
        id: id,
        userEmail: userEmail,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _notificationsCol.doc(id).set(notification.toJson());
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Menandai satu notifikasi sebagai telah dibaca
  static Future<void> markAsRead(String id) async {
    try {
      await _notificationsCol.doc(id).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Menandai semua notifikasi user sebagai telah dibaca
  static Future<void> markAllAsRead(String email) async {
    try {
      final snap = await _notificationsCol
          .where('userEmail', isEqualTo: email)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
