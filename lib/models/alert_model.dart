/// 🔔 Alert Model - Aplikasi Monitoring Kompos
/// Model untuk notifikasi dan alert system

class AlertModel {
  final String id;
  final String type; // temperature_high, humidity_low, ph_abnormal, gas_high
  final String message;
  final double value;
  final DateTime timestamp;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.type,
    required this.message,
    required this.value,
    required this.timestamp,
    this.isRead = false,
  });

  // ==================== FROM JSON ====================
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      value: (json['value'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  // ==================== COPY WITH ====================
  AlertModel copyWith({
    String? id,
    String? type,
    String? message,
    double? value,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  // ==================== HELPERS ====================
  /// Get alert severity level
  String get severity {
    if (type.contains('high') || type.contains('abnormal')) {
      return 'danger';
    } else if (type.contains('low')) {
      return 'warning';
    }
    return 'info';
  }

  /// Get relative time string
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }

  @override
  String toString() {
    return 'Alert($type: $message at $timestamp)';
  }
}
