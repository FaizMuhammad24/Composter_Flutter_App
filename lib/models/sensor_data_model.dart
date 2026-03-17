/// 🌡️ Sensor Data Model - Aplikasi Monitoring Kompos
/// Model untuk data sensor real-time

class SensorDataModel {
  final double temperature; // °C
  final double humidity; // %
  final double ph; // 6-8 ideal
  final int mq4; // ppm (gas metana)
  final DateTime timestamp;

  SensorDataModel({
    required this.temperature,
    required this.humidity,
    required this.ph,
    required this.mq4,
    required this.timestamp,
  });

  // ==================== FROM JSON ====================
  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    return SensorDataModel(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      ph: (json['ph'] as num).toDouble(),
      mq4: json['mq4'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'ph': ph,
      'mq4': mq4,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // ==================== STATUS HELPERS ====================
  /// Get temperature status
  String get temperatureStatus {
    if (temperature < 60) return 'Rendah';
    if (temperature > 65) return 'Tinggi';
    return 'Normal';
  }

  /// Get humidity status
  String get humidityStatus {
    if (humidity < 30) return 'Rendah';
    if (humidity > 60) return 'Tinggi';
    return 'Normal';
  }

  /// Get pH status
  String get phStatus {
    if (ph < 6) return 'Asam';
    if (ph > 8) return 'Basa';
    return 'Normal';
  }

  /// Get gas status
  String get gasStatus {
    if (mq4 > 500) return 'Tinggi';
    if (mq4 > 350) return 'Peringatan';
    return 'Normal';
  }

  /// Check if any sensor is in danger state
  bool get hasDanger {
    return temperature > 65 || humidity < 25 || ph < 5.5 || ph > 8.5 || mq4 > 500;
  }

  /// Check if any sensor is in warning state
  bool get hasWarning {
    return (temperature > 63 && temperature <= 65) ||
        (humidity < 30 && humidity >= 25) ||
        (humidity > 60 && humidity <= 70) ||
        (ph < 6 && ph >= 5.5) ||
        (ph > 8 && ph <= 8.5) ||
        (mq4 > 350 && mq4 <= 500);
  }

  @override
  String toString() {
    return 'SensorData(temp: $temperature°C, humidity: $humidity%, pH: $ph, gas: $mq4 ppm)';
  }
}
