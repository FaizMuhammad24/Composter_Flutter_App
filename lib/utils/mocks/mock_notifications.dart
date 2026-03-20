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
      title: 'SUHU DI ATAS PARAMETER',
      message: 'Suhu komposter 67.0°C (diatas 65°C), Heater dimatikan.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      severity: 'danger',
    ),
    AdminNotification(
      id: 'notif_2',
      type: 'gas_high',
      title: 'GAS MELEBIHI BATAS AMAN',
      message: 'Konsentrasi gas metana 520 ppm (diatas 500 ppm), Exhaust Fan dinyalakan.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      severity: 'danger',
    ),
    AdminNotification(
      id: 'notif_3',
      type: 'ph_low',
      title: 'pH DI BAWAH PARAMETER',
      message: 'pH komposter 5.8 (dibawah 6.0 / terlalu asam), Pompa EM4 dinyalakan.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      severity: 'warning',
      isRead: true,
    ),
    AdminNotification(
      id: 'notif_4',
      type: 'humidity_low',
      title: 'KELEMBABAN DI BAWAH PARAMETER',
      message: 'Kelembaban tanah 28% (dibawah 50%), Pompa Air dinyalakan.',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      severity: 'warning',
    ),
    AdminNotification(
      id: 'notif_5',
      type: 'temperature_low',
      title: 'SUHU DI BAWAH PARAMETER',
      message: 'Suhu komposter 55.0°C (dibawah 60°C), Heater dinyalakan.',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      severity: 'warning',
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
