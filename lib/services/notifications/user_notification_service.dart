import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_notification_model.dart';
import 'package:flutter/foundation.dart';

class UserNotificationService {
  static final _notificationsCol = FirebaseFirestore.instance.collection('notifications');

  /// Stream notifikasi untuk user tertentu
  static Stream<List<AppNotificationModel>> getNotifications(String email) {
    return _notificationsCol
        .where('userEmail', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotificationModel.fromJson(doc.data()))
            .toList());
  }

  /// Peringatan: Setoran baru diajukan (Pending)
  static Future<void> notifyDepositPending(String email, double weight) async {
    await createNotification(
      userEmail: email,
      title: 'Setoran Berhasil Diajukan ♻️',
      message: 'Setoran $weight kg telah diterima. Menunggu verifikasi dari SuperAdmin sebelum poin ditambahkan.',
      type: 'pending',
    );
  }

  /// Peringatan: Setoran berhasil disetujui
  static Future<void> notifyDepositApproved(String email, double weight, int points) async {
    await createNotification(
      userEmail: email,
      title: 'Hore! Poin Baru 🌟',
      message: 'Setoran sampah ($weight kg) telah disetujui. +$points poin telah masuk ke akunmu.',
      type: 'success',
    );
  }

  /// Peringatan: Penukaran hadiah diajukan
  static Future<void> notifyRewardRedeemed(String email, String rewardName) async {
    await createNotification(
      userEmail: email,
      title: 'Hadiah Sedang Diproses 🛍️',
      message: 'Permintaan tukar poin dengan "$rewardName" telah dikirim. Silakan konfirmasi ke Admin untuk pengambilan.',
      type: 'reward',
    );
  }

  /// Peringatan: Milestone Poin
  static Future<void> notifyMilestone(String email, int points) async {
    await createNotification(
      userEmail: email,
      title: 'Selamat! 🎉',
      message: 'Kamu telah mencapai milestone sebesar $points poin! Teruslah mengompos untuk lingkungan yang lebih baik.',
      type: 'success',
    );
  }

  /// Broadcast Pengumuman Global
  static Future<void> broadcastAnnouncement(String title, String message) async {
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in usersSnap.docs) {
        final email = doc.data()['email'];
        if (email != null) {
          final id = _notificationsCol.doc().id;
          final notification = AppNotificationModel(
            id: id,
            userEmail: email,
            title: title,
            message: message,
            type: 'system',
            isRead: false,
            createdAt: DateTime.now(),
          );
          batch.set(_notificationsCol.doc(id), notification.toJson());
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error broadcasting announcement: $e');
    }
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
      debugPrint('Error creating user notification: $e');
    }
  }
}
