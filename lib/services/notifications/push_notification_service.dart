import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/auth/session_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class PushNotificationService {
  // TODO: Ganti dengan App ID dari Dashboard OneSignal Anda
  static const String _oneSignalAppId = "ded6e8d4-838d-46a6-a11b-ddec056dbe68";

  static Future<void> init() async {
    final currentUser = SessionService.getCurrentUser();
    if (currentUser == null) return;

    // Untuk membantu melacak error saat proses pengembangan
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Inisialisasi OneSignal dengan App ID Anda
    OneSignal.initialize(_oneSignalAppId);

    // Minta izin notifikasi ke pengguna (terutama Android 13+ dan iOS)
    OneSignal.Notifications.requestPermission(true);

    // Opsional: Daftarkan User ID agar lebih mudah dilacak di Dashboard OneSignal
    OneSignal.login(currentUser.uid);
    
    // Beri "Tag" pada user ini. 
    // Nanti saat ada peringatan suhu, kita cukup suruh OneSignal mengirim pesan ke SEMUA user yang punya tag "role: admin"
    if (currentUser.isAdmin) {
      OneSignal.User.addTagWithKey("role", "admin");
      debugPrint("OneSignal tag added: role=admin");
    } else {
      OneSignal.User.addTagWithKey("role", "user");
    }
  }

  // --- FUNGSI UNTUK MENGIRIM PUSH NOTIFICATION DARI DALAM APLIKASI ---
  
  static String get _restApiKey => dotenv.env['ONESIGNAL_REST_API_KEY'] ?? '';

  /// Kirim notifikasi ke semua Admin (berdasarkan tag 'role' = 'admin')
  static Future<void> sendPushToAdmins({required String title, required String message}) async {
    try {
      final url = Uri.parse('https://api.onesignal.com/notifications');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: json.encode({
          'app_id': _oneSignalAppId,
          'target_channel': 'push',
          'filters': [
            {'field': 'tag', 'key': 'role', 'relation': '=', 'value': 'admin'}
          ],
          'headings': {'en': title},
          'contents': {'en': message},
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('Push Notification Admin terkirim: $title');
      } else {
        debugPrint('Gagal mengirim Push Notif Admin: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error mengirim Push Notif Admin: $e');
    }
  }

  /// Kirim notifikasi ke User tertentu (berdasarkan userId/uid yang login)
  static Future<void> sendPushToUser({required String userId, required String title, required String message}) async {
    try {
      final url = Uri.parse('https://api.onesignal.com/notifications');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: json.encode({
          'app_id': _oneSignalAppId,
          'target_channel': 'push',
          'include_aliases': {
            'external_id': [userId] 
          },
          // Karena OneSignal terbaru pakai aliases/external_id sesuai OneSignal.login(uid)
          'headings': {'en': title},
          'contents': {'en': message},
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('Push Notification User terkirim: $title');
      } else {
        debugPrint('Gagal mengirim Push Notif User: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error mengirim Push Notif User: $e');
    }
  }
}
