import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../models/app_notification_model.dart';
import 'package:flutter/foundation.dart';
import './push_notification_service.dart';

class UserNotificationService {
  static final _notificationsCol = FirebaseFirestore.instance.collection('notifications');

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static StreamSubscription? _pushSub;
  static DateTime? _initTime;

  /// Inisialisasi plugin notifikasi lokal & mendengarkan record baru Firestore
  static Future<void> initPushNotifications(String userEmail) async {
    if (_isInitialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(settings: const InitializationSettings(android: androidSettings, iOS: iosSettings));
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    _isInitialized = true;
    _initTime = DateTime.now();

    _pushSub = _notificationsCol
        .where('userEmail', isEqualTo: userEmail)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added && !change.doc.metadata.hasPendingWrites) {
          final data = change.doc.data();
          if (data == null) continue;
          final rawTime = data['createdAt'];
          if (rawTime == null) continue;
          
          DateTime docTime;
          if (rawTime is String) {
            docTime = DateTime.tryParse(rawTime) ?? DateTime.now();
          } else {
            docTime = (rawTime as Timestamp).toDate();
          }

          if (_initTime != null && docTime.isAfter(_initTime!)) {
            _showPush(data['title'] ?? 'Info', data['message'] ?? '');
          }
        }
      }
    });
  }

  static void dispose() {
    _pushSub?.cancel();
    _pushSub = null;
    _isInitialized = false;
  }

  static Future<void> _showPush(String title, String body) async {
    const androidDetails = AndroidNotificationDetails('user_alerts_channel', 'User Notifications', importance: Importance.max, priority: Priority.high);
    await _plugin.show(id: DateTime.now().microsecondsSinceEpoch.remainder(2147483647), title: title, body: body, notificationDetails: const NotificationDetails(android: androidDetails));
  }

  /// Stream notifikasi untuk user tertentu
  static Stream<List<AppNotificationModel>> getNotifications(String email) {
    return _notificationsCol
        .where('userEmail', isEqualTo: email)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => AppNotificationModel.fromJson(doc.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Peringatan: Setoran baru diajukan (Pending)
  static Future<void> notifyDepositPending(String email, double weight) async {
    const title = 'Setoran Berhasil Diajukan ♻️';
    await createNotification(
      userEmail: email,
      title: title,
      message: 'Setoran $weight kg telah diterima. Menunggu verifikasi dari Admin sebelum poin ditambahkan.',
      type: 'pending',
    );
  }

  /// Peringatan: Setoran berhasil disetujui
  static Future<void> notifyDepositApproved(String email, double weight, int points) async {
    const title = 'Hore! Poin Baru 🌟';
    final message = 'Setoran sampah ($weight kg) telah disetujui. +$points poin telah masuk ke akunmu.';
    await createNotification(
      userEmail: email,
      title: title,
      message: message,
      type: 'success',
    );
    // Cari uid user berdasarkan email lalu kirim push
    _sendPushByEmail(email, title: title, message: message);
  }

  /// Peringatan: Setoran DITOLAK oleh Admin
  static Future<void> notifyDepositRejected(String email, double weight, {String reason = ''}) async {
    final reasonText = reason.isNotEmpty ? ' Alasan: $reason.' : '';
    const title = 'Setoran Ditolak ❌';
    final message = 'Setoran sampah ($weight kg) Anda telah ditolak.$reasonText Silakan hubungi admin untuk informasi lebih lanjut.';
    await createNotification(
      userEmail: email,
      title: title,
      message: message,
      type: 'error',
    );
    _sendPushByEmail(email, title: title, message: message);
  }

  /// Peringatan: Klaim hadiah diajukan (menunggu konfirmasi SA)
  static Future<void> notifyRewardRedeemed(String email, String rewardName) async {
    await createNotification(
      userEmail: email,
      title: 'Klaim Hadiah Berhasil 🛍️',
      message: 'Permintaan klaim "$rewardName" telah diajukan dan poin berhasil dipotong. Menunggu konfirmasi Admin.',
      type: 'success',
    );
  }

  /// Peringatan: Klaim Hadiah DISETUJUI oleh Admin
  static Future<void> notifyRewardApproved(String email, String rewardName, int quantity) async {
    const title = 'Hadiah Disetujui! 🎉';
    final message = 'Klaim ${quantity}x "$rewardName" telah disetujui. Silakan ambil hadiah di loket terdekat.';
    await createNotification(
      userEmail: email,
      title: title,
      message: message,
      type: 'success',
    );
    _sendPushByEmail(email, title: title, message: message);
  }

  /// Peringatan: Klaim Hadiah DITOLAK oleh Admin (poin dikembalikan)
  static Future<void> notifyRewardRejected(String email, String rewardName, int pointsRefunded) async {
    const title = 'Klaim Hadiah Ditolak';
    final message = 'Klaim "$rewardName" tidak dapat diproses. $pointsRefunded poin telah dikembalikan ke akun Anda.';
    await createNotification(
      userEmail: email,
      title: title,
      message: message,
      type: 'error',
    );
    _sendPushByEmail(email, title: title, message: message);
  }

  /// Peringatan: Milestone Poin
  static Future<void> notifyMilestone(String email, int points) async {
    const title = 'Selamat! 🎉';
    final message = 'Kamu telah mencapai milestone sebesar $points poin! Teruslah mengompos untuk lingkungan yang lebih baik.';
    await createNotification(
      userEmail: email,
      title: title,
      message: message,
      type: 'success',
    );
    _sendPushByEmail(email, title: title, message: message);
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
      // ✅ Kirim push ke SEMUA subscriber (Admin + User)
      PushNotificationService.sendPushToAdmins(title: '📢 $title', message: message);
    } catch (e) {
      debugPrint('Error broadcasting announcement: $e');
    }
  }

  /// Helper: Cari uid user berdasarkan email, lalu kirim push
  static Future<void> _sendPushByEmail(String email, {required String title, required String message}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final uid = snap.docs.first.id;
        PushNotificationService.sendPushToUser(userId: uid, title: title, message: message);
      }
    } catch (e) {
      debugPrint('Error sending push by email: $e');
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
