import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_notification_model.dart';
import 'package:flutter/foundation.dart';
import './user_notification_service.dart';

class ManagementNotificationService {
  static final _notificationsCol = FirebaseFirestore.instance.collection('notifications');

  /// Stream notifikasi untuk admin
  static Stream<List<AppNotificationModel>> getNotifications() {
    return _notificationsCol
        .where('type', whereIn: ['deposit_pending', 'reward_request', 'system_alert'])
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => AppNotificationModel.fromJson(doc.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream jumlah notifikasi Admin yang belum dibaca (untuk badge header)
  static Stream<int> getUnreadCountStream() {
    return _notificationsCol
        .where('type', whereIn: ['deposit_pending', 'reward_request', 'system_alert'])
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ✅ HELPER: Kirim notifikasi ke semua Admin
  static Future<void> _notifyAllAdmins({
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      // Ambil semua user dengan role 'admin'
      final adminSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminSnap.docs.isEmpty) {
        debugPrint('Tidak ada admin untuk dikirim notifikasi');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in adminSnap.docs) {
        final adminEmail = doc.data()['email'] as String?;
        if (adminEmail == null || adminEmail.isEmpty) continue;

        final id = _notificationsCol.doc().id;
        final notification = AppNotificationModel(
          id: id,
          userEmail: adminEmail, // ✅ Kirim ke setiap admin
          title: title,
          message: message,
          type: type,
          isRead: false,
          createdAt: DateTime.now(),
        );
        batch.set(_notificationsCol.doc(id), notification.toJson());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error notifying all admins: $e');
    }
  }

  // ✅ UPDATE: Peringatan setoran baru
  static Future<void> notifyNewDeposit(String userEmail, double weight) async {
    await _notifyAllAdmins(
      title: '♻️ Setoran Baru Menunggu Terima',
      message: 'User $userEmail menginput setoran $weight kg. Silakan cek menu Manajemen > Setoran.',
      type: 'deposit_pending',
    );
  }

  // ✅ UPDATE: Peringatan klaim reward baru
  static Future<void> notifyRewardRequest({
    required String userEmail,
    required String userName,
    required String rewardName,
  }) async {
    await _notifyAllAdmins(
      title: '🎁 Permintaan Hadiah Baru!',
      message: 'User $userName ($userEmail) telah menukarkan poin untuk "$rewardName". Segera siapkan hadiah!',
      type: 'reward_request',
    );
  }

  // ✅ UPDATE: Broadcast system
  static Future<void> broadcastSystemUpdate(String title, String message) async {
    await _notifyAllAdmins(
      title: '📢 Broadcast: $title',
      message: 'Pesan: $message',
      type: 'system_alert',
    );
    await UserNotificationService.broadcastAnnouncement(title, message);
  }

  static Future<void> createNotification({
    required String userEmail,
    required String title,
    required String message,
    required String type,
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
      debugPrint('Error creating admin notification: $e');
    }
  }

  /// Menandai satu notifikasi sebagai telah dibaca
  static Future<void> markAsRead(String id) async {
    try {
      await _notificationsCol.doc(id).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking admin notification as read: $e');
    }
  }

  /// Menghapus satu notifikasi
  static Future<void> deleteNotification(String id) async {
    try {
      await _notificationsCol.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting admin notification: $e');
    }
  }

  /// Menghapus notifikasi deposit pending berdasarkan userEmail dan weight
  static Future<void> clearDepositNotification(String userEmail, double weight) async {
    try {
      final snap = await _notificationsCol
          .where('type', isEqualTo: 'deposit_pending')
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snap.docs) {
        final data = doc.data();
        final message = data['message'] as String? ?? '';
        if (message.contains(userEmail) && message.contains(weight.toString())) {
           batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing deposit notification: $e');
    }
  }

  /// Menandai semua notifikasi Admin sebagai telah dibaca
  static Future<void> markAllAsRead() async {
    try {
      final snap = await _notificationsCol
          .where('type', whereIn: ['deposit_pending', 'reward_request', 'system_alert'])
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all admin notifications as read: $e');
    }
  }

  /// Menghapus semua notifikasi Admin
  static Future<void> deleteAllNotifications() async {
    try {
      final snap = await _notificationsCol
          .where('type', whereIn: ['deposit_pending', 'reward_request', 'system_alert'])
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all admin notifications: $e');
    }
  }
}
