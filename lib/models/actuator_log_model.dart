/// ⚙️ Actuator Log Model - Aplikasi Monitoring Kompos
/// Model untuk history log aktivitas alat/actuator

class ActuatorLogModel {
  final String id;
  final String actuatorName; // exhaust_fan, heater, motor_aduk, pompa_flm, pompa_air
  final String status; // ON, OFF
  final DateTime timestamp;
  final int durationMinutes;
  final String reason;
  final dynamic sensorValue; // nilai sensor saat trigger

  ActuatorLogModel({
    required this.id,
    required this.actuatorName,
    required this.status,
    required this.timestamp,
    required this.durationMinutes,
    required this.reason,
    this.sensorValue,
  });

  // ==================== FROM JSON ====================
  factory ActuatorLogModel.fromJson(Map<String, dynamic> json) {
    return ActuatorLogModel(
      id: json['id'] as String,
      actuatorName: json['actuator_name'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationMinutes: json['duration_minutes'] as int,
      reason: json['reason'] as String,
      sensorValue: json['sensor_value'],
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actuator_name': actuatorName,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'duration_minutes': durationMinutes,
      'reason': reason,
      'sensor_value': sensorValue,
    };
  }

  // ==================== HELPERS ====================
  /// Check if actuator is ON
  bool get isOn => status.toUpperCase() == 'ON';

  /// Get actuator display name
  String get actuatorDisplayName {
    switch (actuatorName.toLowerCase()) {
      case 'exhaust_fan':
        return 'Exhaust Fan';
      case 'heater':
        return 'Heater';
      case 'motor_aduk':
        return 'Motor Aduk';
      case 'pompa_flm':
        return 'Pompa FLM';
      case 'pompa_air':
        return 'Pompa Air';
      default:
        return actuatorName;
    }
  }

  /// Get duration display string
  String get durationDisplay {
    if (durationMinutes < 60) {
      return '$durationMinutes menit';
    } else {
      final hours = (durationMinutes / 60).floor();
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours jam';
      }
      return '$hours jam $minutes menit';
    }
  }

  /// Get formatted sensor value
  String get sensorValueFormatted {
    if (sensorValue == null) return '-';
    
    if (sensorValue is double) {
      return sensorValue.toStringAsFixed(1);
    }
    
    return sensorValue.toString();
  }

  @override
  String toString() {
    return 'ActuatorLog($actuatorDisplayName $status at $timestamp)';
  }
}
