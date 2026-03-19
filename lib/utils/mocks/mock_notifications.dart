class AdminNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String severity;

  AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.severity,
  });
}

class MockNotifications {
  static final List<AdminNotification> _notifications = [
    AdminNotification(
      id: 'notif_1',
      type: 'temperature_high',
      title: 'SUHU TINGGI',
      message: 'Suhu mencapai 62.5°C, Heater telah dimatikan otomatis.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      severity: 'danger',
    ),
    AdminNotification(
      id: 'notif_2',
      type: 'gas_high',
      title: 'GAS BERBAHAYA',
      message: 'Level gas metana 520 ppm, Exhaust Fan diaktifkan.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      severity: 'danger',
    ),
    AdminNotification(
      id: 'notif_3',
      type: 'ph_abnormal',
      title: 'pH TIDAK NORMAL',
      message: 'pH terdeteksi 5.8 (terlalu asam), Pompa EM4 aktif.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      severity: 'warning',
      isRead: true,
    ),
    AdminNotification(
      id: 'notif_4',
      type: 'humidity_low',
      title: 'KELEMBABAN RENDAH',
      message: 'Kelembaban 28%, Pompa Air diaktifkan untuk penyiraman.',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      severity: 'warning',
    ),
    AdminNotification(
      id: 'notif_5',
      type: 'system_info',
      title: 'PENGADUKAN SELESAI',
      message: 'Motor aduk telah menyelesaikan jadwal pengadukan rutin.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      severity: 'info',
      isRead: true,
    ),
  ];

  static List<AdminNotification> getAllNotifications() => _notifications;
  static List<AdminNotification> getUnreadNotifications() => _notifications.where((n) => !n.isRead).toList();
  
  static void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) _notifications[index].isRead = true;
  }

  static void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
  }
}
