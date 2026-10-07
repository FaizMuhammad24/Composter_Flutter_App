import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_notification_model.dart';
import 'package:flutter/foundation.dart';

class AppNotificationService {
  static final _notificationsCol = FirebaseFirestore.instance.collection('notifications');

  static String _cleanUser(String emailOrUsername) {
    final str = emailOrUsername.trim().toLowerCase();
    return str.contains('@') ? str.split('@').first : str;
  }

  /// Mendapatkan stream notifikasi untuk user tertentu (dengan deduplikasi & pencocokan username)
  static Stream<List<AppNotificationModel>> getUserNotificationsStream(String userEmail) {
    final targetUser = _cleanUser(userEmail);
    return _notificationsCol
        .snapshots()
        .map((snap) {
          final list = <AppNotificationModel>[];
          for (var doc in snap.docs) {
            final data = doc.data();
            final docUser = _cleanUser(data['userEmail']?.toString() ?? '');
            if (docUser == targetUser) {
              list.add(AppNotificationModel.fromJson(data));
            }
          }
          
          final Map<String, AppNotificationModel> uniqueMap = {};
          for (var item in list) {
            final minuteKey = '${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day} ${item.createdAt.hour}:${item.createdAt.minute}';
            final key = '${item.title}_${item.message}_$minuteKey';
            if (!uniqueMap.containsKey(key)) {
              uniqueMap[key] = item;
            }
          }

          final result = uniqueMap.values.toList();
          result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return result;
        });
  }

  /// Mendapatkan jumlah notifikasi yang belum dibaca
  static Stream<int> getUnreadCountStream(String email) {
    return getUserNotificationsStream(email).map((list) => list.where((n) => !n.isRead).length);
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
      final targetUser = _cleanUser(email);
      final snap = await _notificationsCol.get();
      
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;
      for (var doc in snap.docs) {
        final docUser = _cleanUser(doc.data()['userEmail']?.toString() ?? '');
        final isRead = doc.data()['isRead'] as bool? ?? false;
        if (docUser == targetUser && !isRead) {
          batch.update(doc.reference, {'isRead': true});
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Menghapus satu notifikasi berdasarkan ID (dan membersihkan duplikatnya di Firestore)
  static Future<void> deleteNotification(String id) async {
    try {
      final targetDoc = await _notificationsCol.doc(id).get();
      if (targetDoc.exists) {
        final data = targetDoc.data();
        if (data != null) {
          final title = data['title'] as String? ?? '';
          final message = data['message'] as String? ?? '';
          final targetUser = _cleanUser(data['userEmail']?.toString() ?? '');

          final snap = await _notificationsCol.get();
          final batch = FirebaseFirestore.instance.batch();
          int count = 0;
          for (var doc in snap.docs) {
            final docData = doc.data();
            final docUser = _cleanUser(docData['userEmail']?.toString() ?? '');
            final docTitle = docData['title'] as String? ?? '';
            final docMessage = docData['message'] as String? ?? '';

            if (docUser == targetUser && docTitle == title && docMessage == message) {
              batch.delete(doc.reference);
              count++;
            }
          }
          if (count > 0) {
            await batch.commit();
            return;
          }
        }
      }
      await _notificationsCol.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Menghapus semua notifikasi user
  static Future<void> deleteAllNotifications(String email) async {
    try {
      final targetUser = _cleanUser(email);
      final allSnap = await _notificationsCol.get();
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;
      for (var doc in allSnap.docs) {
        final docUser = _cleanUser(doc.data()['userEmail']?.toString() ?? '');
        if (docUser == targetUser) {
          batch.delete(doc.reference);
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }
}
