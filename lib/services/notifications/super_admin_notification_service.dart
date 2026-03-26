import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_notification_model.dart';
import 'package:flutter/foundation.dart';
import './user_notification_service.dart';

class SuperAdminNotificationService {
  static final _notificationsCol = FirebaseFirestore.instance.collection('notifications');

  /// Stream notifikasi untuk super admin
  static Stream<List<AppNotificationModel>> getNotifications() {
    return _notificationsCol
        .where('type', whereIn: ['deposit_pending', 'reward_request', 'system_alert'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotificationModel.fromJson(doc.data()))
            .toList());
  }

  /// Peringatan: Ada setoran baru yang perlu ACC
  static Future<void> notifyNewDeposit(String userEmail, double weight) async {
    await createNotification(
      userEmail: 'superadmin@icompost.com',
      title: '♻️ Setoran Baru Menunggu ACC',
      message: 'User $userEmail menginput setoran $weight kg. Silakan cek menu Manajemen > Setoran.',
      type: 'deposit_pending',
    );
  }

  /// Peringatan: Ada user yang menukarkan poin (Hadiah)
  static Future<void> notifyRewardRequest({
    required String userEmail,
    required String userName,
    required String rewardName,
  }) async {
    await createNotification(
      userEmail: 'superadmin@icompost.com',
      title: '🎁 Permintaan Hadiah Baru!',
      message: 'User $userName ($userEmail) telah menukarkan poin untuk "$rewardName". Segera siapkan hadiah!',
      type: 'reward_request',
    );
  }

  /// Peringatan: Broadcast update sistem ke semua user
  static Future<void> broadcastSystemUpdate(String title, String message) async {
    // Kirim notifikasi ke superadmin sendiri sebagai record
    await createNotification(
      userEmail: 'superadmin@icompost.com',
      title: '📢 Broadcast: $title',
      message: 'Pesan: $message',
      type: 'system_alert',
    );
    
    // Sebar ke semua user
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
      debugPrint('Error creating super admin notification: $e');
    }
  }
}
