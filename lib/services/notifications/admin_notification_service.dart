import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/app_notification_model.dart';

/// Model notifikasi lokal untuk sensor
class LocalAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // 'danger' | 'warning' | 'info'
  final DateTime timestamp;
  bool isRead;

  LocalAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
  });
}

class AdminNotificationService {
  static final _notificationsCol = FirebaseFirestore.instance.collection('notifications');

  // Logic Sensor dari NotificationService
  static final AdminNotificationService _sensorInstance = AdminNotificationService._internal();
  factory AdminNotificationService() => _sensorInstance;
  AdminNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static final ValueNotifier<List<LocalAlert>> alertsNotifier = ValueNotifier([]);
  static List<LocalAlert> get alerts => alertsNotifier.value;
  static final ValueNotifier<bool> deviceOfflineNotifier = ValueNotifier(false);
  static bool get isDeviceOffline => deviceOfflineNotifier.value;

  final Map<String, DateTime> _lastNotified = {};
  final Duration _cooldown = const Duration(minutes: 15);

  StreamSubscription? _rtdbSubscription;
  Timer? _statusCheckTimer;
  DateTime? _lastDataReceive;
  DateTime? _initTime;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _listenToFirebase();
    _initTime = DateTime.now();
    _startStatusTimer();
    _isInitialized = true;
    startMaintenanceChecks();
  }

  void _startStatusTimer() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now();
      
      // Case 1: Already received some data, check for staleness from last received time
      if (_lastDataReceive != null) {
        final diff = now.difference(_lastDataReceive!);
        if (diff.inSeconds > 40) { // 40 seconds tolerance
          if (!deviceOfflineNotifier.value) {
            deviceOfflineNotifier.value = true;
            notifyDeviceOffline();
          }
        }
      } 
      // Case 2: No data received yet since init, check against init time
      else if (_initTime != null) {
        final diff = now.difference(_initTime!);
        if (diff.inSeconds > 30) { // 30 seconds wait for first data
          if (!deviceOfflineNotifier.value) {
            deviceOfflineNotifier.value = true;
            notifyDeviceOffline();
          }
        }
      }
    });
  }

  bool _isDataStale(Map<dynamic, dynamic> data) {
    // 1. Cek via Unix Timestamp
    if (data.containsKey('unix_time')) {
      final int espUnix = (data['unix_time'] as num).toInt();
      final int phoneUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Only stale if phone time is significantly ahead of ESP time
      return (phoneUnix - espUnix) > 60; // 1 minute tolerance
    }
    
    // 2. Fallback ke String "time" (HH:mm:ss)
    final String? timeStr = data['time']?.toString();
    if (timeStr == null || timeStr.isEmpty) return false; // Can't tell, assume ok
    try {
      final parts = timeStr.split(':');
      if (parts.length != 3) return false;
      final now = DateTime.now();
      final dataTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return now.difference(dataTime).inSeconds > 60;
    } catch (e) {
      return false;
    }
  }

  void _listenToFirebase() {
    _rtdbSubscription = FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      final double temp = (data['temperature'] as num?)?.toDouble() ?? 60.0;
      final double soil = (data['soil'] as num?)?.toDouble() ?? 60.0;
      final double ph   = (data['ph'] as num?)?.toDouble() ?? 7.0;
      final int gas     = (data['gas'] as num?)?.toInt() ?? 0;

      final bool stale = _isDataStale(data);
      if (!stale) {
        _lastDataReceive = DateTime.now();
        if (deviceOfflineNotifier.value) {
          deviceOfflineNotifier.value = false;
          notifyDeviceOnline();
        }
      }

      if (deviceOfflineNotifier.value) return; // Don't check sensors if offline

      _check('temp_failed', temp == 100.0, 'SENSOR SUHU TIDAK TERBACA', 'Data suhu tidak valid (100.0°C). Cek koneksi sensor.', 'danger');
      _check('soil_failed', soil == 100.0 || soil == 0.0, 'SENSOR KELEMBABAN TIDAK TERBACA', 'Data kelembaban tidak valid. Cek koneksi sensor.', 'danger');
      _check('ph_failed', ph == 100.0 || ph == 10.0 || ph == 0.0, 'SENSOR pH TIDAK TERBACA', 'Data pH tidak valid. Cek koneksi sensor.', 'danger');
      _check('gas_failed', gas == 100, 'SENSOR GAS TIDAK TERBACA', 'Data gas tidak valid. Cek koneksi sensor.', 'danger');

      if (temp != 100.0) {
        _check('temp_low',  temp < 60.0, 'SUHU DI BAWAH PARAMETER', 'Suhu komposter ${temp.toStringAsFixed(1)}°C (dibawah 60°C).', 'warning');
        _check('temp_high', temp > 65.0, 'SUHU DI ATAS PARAMETER', 'Suhu komposter ${temp.toStringAsFixed(1)}°C (diatas 65°C).', 'danger');
      }
      if (soil != 100.0 && soil != 0.0) {
        _check('soil_low',  soil < 50.0, 'KELEMBABAN DI BAWAH PARAMETER', 'Kelembaban tanah ${soil.toStringAsFixed(0)}% (dibawah 50%).', 'warning');
        _check('soil_high', soil > 70.0, 'KELEMBABAN DI ATAS PARAMETER', 'Kelembaban tanah ${soil.toStringAsFixed(0)}% (diatas 70%).', 'warning');
      }
      if (ph != 100.0 && ph != 10.0 && ph != 0.0) {
        _check('ph_low',  ph < 6.0, 'pH DI BAWAH PARAMETER', 'pH komposter ${ph.toStringAsFixed(1)} (dibawah 6.0).', 'warning');
        _check('ph_high', ph > 8.0, 'pH DI ATAS PARAMETER', 'pH komposter ${ph.toStringAsFixed(1)} (diatas 8.0).', 'warning');
      }
      if (gas != 100) {
        _check('gas_danger', gas > 500, 'GAS MELEBIHI BATAS AMAN', 'Konsentrasi gas metana $gas ppm.', 'danger');
      }
    });
  }

  void _addAlert(String title, String message, String severity) {
    final now = DateTime.now();
    alertsNotifier.value = [
      LocalAlert(id: '${title.hashCode}-${now.millisecondsSinceEpoch}', title: title, message: message, severity: severity, timestamp: now),
      ...alertsNotifier.value
    ];
    _showPush(title, message);
  }

  void _check(String key, bool condition, String title, String message, String severity, {bool bypassCooldown = false}) {
    final now = DateTime.now();
    if (condition) {
      final last = _lastNotified[key];
      if (bypassCooldown || last == null || now.difference(last) > _cooldown) {
        _lastNotified[key] = now;
        _addAlert(title, message, severity);
      }
    } else {
      // If condition is false, we might want to clear status for some keys
      if (severity == 'info') {
         // for info alerts, we don't usually clear unless it's a specific toggle
      } else {
        // For danger/warning, if it's healthy now, we might want to allow re-notification later
        // but typically we keep it in _lastNotified to respect cooldown even after recovery
        // unless it's a specific toggle like connectivity.
        // Original recovery logic:
        if (_lastNotified.containsKey(key) && !key.contains('failed') && key != 'esp_offline') {
          _lastNotified.remove(key);
          String recoveryTitle = title;
          if (title.contains('DI BAWAH')) recoveryTitle = title.replaceAll('DI BAWAH', 'SUDAH KEMBALI');
          else if (title.contains('DI ATAS')) recoveryTitle = title.replaceAll('DI ATAS', 'SUDAH KEMBALI');
          else if (title.contains('MELEBIHI')) recoveryTitle = title.replaceAll('MELEBIHI', 'SUDAH KEMBALI');
          else recoveryTitle = 'STATUS $key NORMAL';

          _addAlert('$recoveryTitle ✅', 'Parameter $key telah kembali ke batas normal.', 'info');
        } else {
          _lastNotified.remove(key);
        }
      }
    }
  }

  void clearAll() {
    alertsNotifier.value = [];
  }

  void markAllAsRead() {
    final newList = alerts.map((a) {
      a.isRead = true;
      return a;
    }).toList();
    alertsNotifier.value = newList;
  }

  void notifyDeviceOffline() {
    debugPrint('AdminNotificationService: Device Offline detected');
    _lastNotified.remove('esp_online'); // Allow re-notifying "Online" later
    _check('esp_offline', true, 'ESP32 TERPUTUS (OFFLINE)', 'Koneksi ke alat i-Composter hilang.', 'danger', bypassCooldown: true);
  }

  void notifyDeviceOnline() {
    debugPrint('AdminNotificationService: Device Online detected');
    if (_lastNotified.containsKey('esp_offline')) {
      _lastNotified.remove('esp_offline'); // Allow re-notifying "Offline" later
      _check('esp_online', true, 'ESP32 TERHUBUNG KEMBALI', 'Koneksi ke alat i-Composter telah pulih.', 'info', bypassCooldown: true);
    }
  }

  Future<void> _showPush(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails('komposter_alerts_channel', 'Peringatan Komposter', importance: Importance.max, priority: Priority.high);
    await _plugin.show(id: DateTime.now().millisecond, title: title, body: body, notificationDetails: const NotificationDetails(android: androidDetails));
  }

  // ============ MAINTENANCE & COMPOST NOTIFICATIONS ============

  Timer? _maintenanceTimer;
  Timer? _inactivityTimer;

  void startMaintenanceChecks() {
    // Check calibration every hour
    _maintenanceTimer = Timer.periodic(const Duration(hours: 1), (_) => _checkCalibrationReminders());
    // Check inactivity every 10 minutes
    _inactivityTimer = Timer.periodic(const Duration(minutes: 10), (_) => _checkInactivity());
    // Initial checks
    _checkCalibrationReminders();
    _checkCompostMaturity();
  }

  Future<void> _checkCalibrationReminders() async {
    final sensors = ['ph', 'temperature', 'soil', 'gas'];
    final labels = {'ph': 'pH', 'temperature': 'Suhu', 'soil': 'Kelembaban', 'gas': 'Gas'};
    
    for (var sensor in sensors) {
      try {
        final snap = await FirebaseDatabase.instance.ref('komposter/calibration/$sensor').get();
        if (snap.value != null) {
          final int ts = (snap.value as num).toInt();
          final lastCal = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          final daysSince = DateTime.now().difference(lastCal).inDays;
          if (daysSince >= 30) {
            _check('cal_$sensor', true, 'KALIBRASI ${labels[sensor]!.toUpperCase()} DIPERLUKAN', 
              'Sensor ${labels[sensor]} belum dikalibrasi selama $daysSince hari. Disarankan kalibrasi setiap 30 hari.', 'warning');
          }
        }
      } catch (e) {
        debugPrint('Error checking calibration for $sensor: $e');
      }
    }
  }

  void _checkInactivity() {
    if (_lastDataReceive == null) return;
    final hours = DateTime.now().difference(_lastDataReceive!).inHours;
    if (hours >= 24) {
      _check('inactivity_24h', true, 'TIDAK ADA AKTIVITAS 24 JAM', 
        'Tidak ada perubahan data sensor selama $hours jam terakhir.', 'warning');
    }
  }

  Future<void> _checkCompostMaturity() async {
    try {
      final batchSnap = await FirebaseDatabase.instance.ref('komposter/batch_start').get();
      if (batchSnap.value != null) {
        final int ts = (batchSnap.value as num).toInt();
        final start = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        final days = DateTime.now().difference(start).inDays;
        if (days >= 21) {
          _check('compost_ready', true, 'KOMPOS SIAP PANEN', 
            'Proses komposting telah berjalan $days hari (target: 21 hari). Periksa parameter kematangan di Status Kompos.', 'info');
        }
      }
    } catch (e) {
      debugPrint('Error checking compost maturity: $e');
    }
  }

  void dispose() { 
    _rtdbSubscription?.cancel(); 
    _statusCheckTimer?.cancel();
    _maintenanceTimer?.cancel();
    _inactivityTimer?.cancel();
    _rtdbSubscription = null; 
    _statusCheckTimer = null;
    _isInitialized = false; 
  }

  // Logic Firestore lama (Tetap dipertahankan untuk referensi admin jika perlu)
  static Stream<List<AppNotificationModel>> getFirestoreNotifications() {
    return _notificationsCol.orderBy('createdAt', descending: true).snapshots().map((snap) => snap.docs.map((doc) => AppNotificationModel.fromJson(doc.data())).toList());
  }

  static Future<void> createNotification({required String userEmail, required String title, required String message, required String type}) async {
    try {
      final id = _notificationsCol.doc().id;
      final notification = AppNotificationModel(id: id, userEmail: userEmail, title: title, message: message, type: type, isRead: false, createdAt: DateTime.now());
      await _notificationsCol.doc(id).set(notification.toJson());
    } catch (e) { debugPrint('Error creating admin notification: $e'); }
  }
}
