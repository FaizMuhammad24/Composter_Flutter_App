import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:flutter/material.dart';

/// Model notifikasi lokal
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

/// Parameter Sensor Komposter:
/// - Suhu Optimal        : 60°C – 65°C
/// - Kelembaban Optimal  : 50%  – 70%
/// - pH Optimal          : 6.0  – 8.0
/// - Gas Aman            : < 500 ppm
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // Daftar alert yang pernah terjadi (dibaca oleh UI)
  static final ValueNotifier<List<LocalAlert>> alertsNotifier = ValueNotifier([]);
  static List<LocalAlert> get alerts => alertsNotifier.value;

  // Cooldown 15 menit per kondisi
  final Map<String, DateTime> _lastNotified = {};
  final Duration _cooldown = const Duration(minutes: 15);

  StreamSubscription? _rtdbSubscription;
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
    _isInitialized = true;
  }

  void _listenToFirebase() {
    _rtdbSubscription = FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

      final double temp = (data['temperature'] as num?)?.toDouble() ?? 60.0;
      final double soil = (data['soil'] as num?)?.toDouble() ?? 60.0;
      final double ph   = (data['ph'] as num?)?.toDouble() ?? 7.0;
      final int gas     = (data['gas'] as num?)?.toInt() ?? 0;

      // === SENSOR FAILURE (Stuck/Disconnected) ===
      _check('temp_failed', temp == 100.0,
        'SENSOR SUHU TIDAK TERBACA',
        'Data suhu tidak valid (100.0°C). Cek koneksi sensor suhu/DS18B20.',
        'danger');

      _check('soil_failed', soil == 100.0 || soil == 0.0,
        'SENSOR KELEMBABAN TIDAK TERBACA',
        'Data kelembaban tidak valid. Cek koneksi sensor soil.',
        'danger');
      
      _check('ph_failed', ph == 100.0 || ph == 10.0 || ph == 0.0,
        'SENSOR pH TIDAK TERBACA',
        'Data pH tidak valid. Cek koneksi sensor pH.',
        'danger');

      _check('gas_failed', gas == 100,
        'SENSOR GAS TIDAK TERBACA',
        'Data gas tidak valid. Cek koneksi sensor MQ4.',
        'danger');

      // === NORMAL PARAMETER CHECKS (Only if not failed) ===
      if (temp != 100.0) {
        _check('temp_low',  temp < 60.0,
          'SUHU DI BAWAH PARAMETER',
          'Suhu komposter ${temp.toStringAsFixed(1)}°C (dibawah 60°C), Heater dinyalakan.',
          'warning');
        _check('temp_high', temp > 65.0,
          'SUHU DI ATAS PARAMETER',
          'Suhu komposter ${temp.toStringAsFixed(1)}°C (diatas 65°C), Heater dimatikan.',
          'danger');
      }

      if (soil != 100.0 && soil != 0.0) {
        _check('soil_low',  soil < 50.0,
          'KELEMBABAN DI BAWAH PARAMETER',
          'Kelembaban tanah ${soil.toStringAsFixed(0)}% (dibawah 50%), Pompa Air dinyalakan.',
          'warning');
        _check('soil_high', soil > 70.0,
          'KELEMBABAN DI ATAS PARAMETER',
          'Kelembaban tanah ${soil.toStringAsFixed(0)}% (diatas 70%), Pompa Air dimatikan.',
          'warning');
      }

      if (ph != 100.0 && ph != 10.0 && ph != 0.0) {
        _check('ph_low',  ph < 6.0,
          'pH DI BAWAH PARAMETER',
          'pH komposter ${ph.toStringAsFixed(1)} (dibawah 6.0 / terlalu asam), Pompa EM4 dinyalakan.',
          'warning');
        _check('ph_high', ph > 8.0,
          'pH DI ATAS PARAMETER',
          'pH komposter ${ph.toStringAsFixed(1)} (diatas 8.0 / terlalu basa), Pompa EM4 dimatikan.',
          'warning');
      }

      if (gas != 100) {
        _check('gas_danger', gas > 500,
          'GAS MELEBIHI BATAS AMAN',
          'Konsentrasi gas metana $gas ppm (diatas 500 ppm), Exhaust Fan dinyalakan.',
          'danger');
      }
    });
  }

  void _check(String key, bool triggered, String title, String body, String severity) {
    if (triggered) {
      final now = DateTime.now();
      final last = _lastNotified[key];
      if (last == null || now.difference(last) > _cooldown) {
        _lastNotified[key] = now;
        // Simpan ke list yang bisa dibaca UI
        alertsNotifier.value = [
          LocalAlert(
            id: '$key-${now.millisecondsSinceEpoch}',
            title: title,
            message: body,
            severity: severity,
            timestamp: now,
          ),
          ...alertsNotifier.value
        ];
        _showPush(title, body);
        debugPrint('🔔 Notifikasi: $title');
      }
    } else if (key != 'esp_offline') {
      _lastNotified.remove(key);
    }
  }

  // Metode publik untuk dipanggil dari UI (Misal: AdminStatusScreen)
  void notifyDeviceOffline() {
    _check('esp_offline', true, 
      'ESP32 TERPUTUS (OFFLINE)', 
      'Koneksi ke alat i-Composter hilang. Cek daya atau jaringan WiFi alat.', 
      'danger');
  }

  void notifyDeviceOnline() {
    if (_lastNotified.containsKey('esp_offline')) {
      _lastNotified.remove('esp_offline');
      // Opsional: kirim info online kembali
      _check('esp_online', true, 
        'ESP32 TERHUBUNG KEMBALI', 
        'Koneksi ke alat i-Composter telah pulih.', 
        'info');
    }
  }

  Future<void> _showPush(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'komposter_alerts_channel',
      'Peringatan Komposter',
      channelDescription: 'Notifikasi peringatan ambang batas sensor',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFFFFA726),
    );
    await _plugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  void dispose() {
    _rtdbSubscription?.cancel();
    _rtdbSubscription = null;
    _isInitialized = false;
  }
}
