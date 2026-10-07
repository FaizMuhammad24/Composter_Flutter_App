/// 🌡️ Sensor Data Model - Aplikasi Monitoring Kompos
/// Model untuk data sensor real-time

class SensorDataModel {
  final double temperature; // °C
  final double humidity; // %
  final int mq4; // ppm (gas metana)
  final DateTime timestamp;

  // Thresholds dari Firebase (diperbarui setiap kali data diterima)
  final double tempMin;
  final double tempMax;
  final double soilMin;
  final double soilMax;
  final double gasMax;

  SensorDataModel({
    required this.temperature,
    required this.humidity,
    required this.mq4,
    required this.timestamp,
    this.tempMin = 28.0,
    this.tempMax = 33.0,
    this.soilMin = 25.0,
    this.soilMax = 85.0,
    this.gasMax = 100.0,
  });

  // ==================== FROM JSON ====================
  factory SensorDataModel.fromJson(Map<dynamic, dynamic> json) {
    final thresholds = json['thresholds'] as Map?;
    final tempTh = thresholds?['temperature'] as Map?;
    final soilTh = thresholds?['soil'] as Map?;
    final gasTh  = thresholds?['gas'] as Map?;

    return SensorDataModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity:    (json['soil'] as num?)?.toDouble() ?? 0.0,
      mq4:         (json['gas'] as num?)?.toInt() ?? 0,
      timestamp:   DateTime.now(),
      tempMin: (tempTh?['min'] as num?)?.toDouble() ?? 28.0,
      tempMax: (tempTh?['max'] as num?)?.toDouble() ?? 33.0,
      soilMin: (soilTh?['min'] as num?)?.toDouble() ?? 25.0,
      soilMax: (soilTh?['max'] as num?)?.toDouble() ?? 85.0,
      gasMax:  (gasTh?['max'] as num?)?.toDouble() ?? 100.0,
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'soil': humidity,
      'gas': mq4,
      'time': timestamp.toIso8601String(),
    };
  }

  // ==================== STATUS HELPERS (Dynamic dari Firebase threshold) ====================

  /// Get temperature status
  String get temperatureStatus {
    if (!isTempHealthy) return 'Gagal';
    if (temperature < tempMin) return 'Rendah';
    if (temperature > tempMax) return 'Tinggi';
    return 'Normal';
  }

  /// Get humidity status
  String get humidityStatus {
    if (!isSoilHealthy) return 'Gagal';
    if (humidity < soilMin) return 'Rendah';
    if (humidity > soilMax) return 'Tinggi';
    return 'Normal';
  }

  /// Get gas status
  String get gasStatus {
    if (!isGasHealthy) return 'Gagal';
    if (mq4 > gasMax) return 'Bahaya';
    if (mq4 > gasMax * 0.7) return 'Peringatan';
    return 'Normal';
  }

  bool get isTempHealthy => temperature > 0.0 && temperature != 100.0;
  bool get isSoilHealthy => humidity > 0.0 && humidity != 100.0;
  bool get isGasHealthy  => mq4 >= 0 && mq4 != 100;

  /// Check if any sensor is in danger state
  bool get hasDanger {
    return (isTempHealthy && temperature > tempMax) ||
           (isSoilHealthy && humidity < soilMin * 0.6) ||
           (isGasHealthy && mq4 > gasMax);
  }

  /// Check if any sensor is in warning state
  bool get hasWarning {
    return (isTempHealthy && temperature < tempMin) ||
           (isSoilHealthy && (humidity < soilMin || humidity > soilMax)) ||
           (isGasHealthy && mq4 > gasMax * 0.7);
  }

  @override
  String toString() {
    return 'SensorData(temp: $temperature°C, humidity: $humidity%, gas: $mq4 ppm)';
  }
}
