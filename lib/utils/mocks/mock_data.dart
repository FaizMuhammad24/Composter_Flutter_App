import 'dart:math';

/// 🎲 Mock Data Generator - Aplikasi Monitoring Kompos
/// Dummy data generator untuk testing tanpa backend/Firebase

class MockData {
  MockData._();
  
  static final Random _random = Random();

  // ==================== SENSOR DATA ====================
  /// Generate random sensor data (current)
  static Map<String, dynamic> getSensorData() {
    return {
      'temperature': 52.0 + _random.nextDouble() * 13.0, // 52-65°C
      'humidity': 25.0 + _random.nextDouble() * 45.0, // 25-70%
      'ph': 5.5 + _random.nextDouble() * 3.0, // 5.5-8.5
      'mq4': 200 + _random.nextInt(400), // 200-600 ppm
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Generate sensor history (untuk grafik)
  static List<Map<String, dynamic>> getSensorHistory(String sensorType, int hours) {
    List<Map<String, dynamic>> history = [];
    DateTime now = DateTime.now();

    for (int i = hours - 1; i >= 0; i--) {
      double value;
      switch (sensorType.toLowerCase()) {
        case 'temperature':
        case 'suhu':
          value = 52.0 + _random.nextDouble() * 13.0;
          break;
        case 'humidity':
        case 'kelembaban':
          value = 25.0 + _random.nextDouble() * 45.0;
          break;
        case 'ph':
          value = 5.5 + _random.nextDouble() * 3.0;
          break;
        case 'gas':
        case 'mq4':
          value = 200.0 + _random.nextDouble() * 400.0;
          break;
        default:
          value = 0.0;
      }

      history.add({
        'value': value,
        'timestamp': now.subtract(Duration(hours: i)).toIso8601String(),
      });
    }

    return history;
  }

  // ==================== ACTUATOR STATUS ====================
  /// Get actuator status (ON/OFF) based on sensor values
  static Map<String, dynamic> getActuatorStatus() {
    final sensorData = getSensorData();
    return {
      'exhaust_fan': sensorData['mq4'] > 500,
      'heater': sensorData['temperature'] < 60,
      'motor_aduk': _random.nextBool(),
      'pompa_em4': sensorData['ph'] < 6 || sensorData['ph'] > 8,
      'pompa_air': sensorData['humidity'] < 30,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ==================== ACTUATOR LOG ====================
  /// Generate actuator log history
  static List<Map<String, dynamic>> getActuatorLog(String actuatorName, int count) {
    List<Map<String, dynamic>> logs = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < count; i++) {
      bool isOn = _random.nextBool();
      int durationMinutes = 5 + _random.nextInt(55); // 5-60 minutes

      Map<String, dynamic> log = {
        'id': 'log_${now.millisecondsSinceEpoch}_$i',
        'actuator_name': actuatorName,
        'status': isOn ? 'ON' : 'OFF',
        'timestamp': now.subtract(Duration(hours: i * 2)).toIso8601String(),
        'duration_minutes': durationMinutes,
      };

      // Tambahkan reason berdasarkan actuator
      switch (actuatorName.toLowerCase()) {
        case 'exhaust_fan':
          log['reason'] = isOn ? 'Gas tinggi (${500 + _random.nextInt(100)} ppm)' : 'Gas normal';
          log['sensor_value'] = isOn ? 500 + _random.nextInt(100) : 200 + _random.nextInt(300);
          break;
        case 'heater':
          log['reason'] = isOn ? 'Suhu rendah (${50 + _random.nextInt(10)}°C)' : 'Suhu normal';
          log['sensor_value'] = isOn ? 50 + _random.nextInt(10) : 60 + _random.nextInt(5);
          break;
        case 'motor_aduk':
          log['reason'] = isOn ? 'Jadwal pengadukan' : 'Selesai pengadukan';
          log['sensor_value'] = null;
          break;
        case 'pompa_em4':
          double phValue = isOn ? (5.0 + _random.nextDouble()) : (6.5 + _random.nextDouble() * 1.5);
          log['reason'] = isOn ? 'pH tidak normal (${phValue.toStringAsFixed(1)})' : 'pH normal';
          log['sensor_value'] = phValue;
          break;
        case 'pompa_air':
          log['reason'] = isOn ? 'Kelembaban rendah (${20 + _random.nextInt(10)}%)' : 'Kelembaban normal';
          log['sensor_value'] = isOn ? 20 + _random.nextInt(10) : 30 + _random.nextInt(30);
          break;
      }

      logs.add(log);
    }

    return logs;
  }

  // ==================== ALERTS / NOTIFICATIONS ====================
  /// Generate random alerts
  static List<Map<String, dynamic>> getAlerts(int count) {
    List<Map<String, dynamic>> alerts = [];
    List<String> types = ['temperature_high', 'humidity_low', 'ph_abnormal', 'gas_high'];
    List<String> messages = [
      'Suhu terlalu tinggi!',
      'Kelembaban terlalu rendah!',
      'pH di luar range normal!',
      'Gas metana tinggi!',
    ];

    DateTime now = DateTime.now();

    for (int i = 0; i < count; i++) {
      int typeIndex = _random.nextInt(types.length);
      alerts.add({
        'id': 'alert_${now.millisecondsSinceEpoch}_$i',
        'type': types[typeIndex],
        'message': messages[typeIndex],
        'value': _random.nextDouble() * 100,
        'timestamp': now.subtract(Duration(hours: i)).toIso8601String(),
        'is_read': _random.nextBool(),
      });
    }

    return alerts;
  }

  // ==================== REWARDS ====================
  /// Get dummy rewards catalog
  static List<Map<String, dynamic>> getRewards() {
    return [
      {
        'id': '1',
        'name': 'Voucher Alfamart 50k',
        'description': 'Voucher belanja senilai Rp 50.000 berlaku di seluruh Alfamart',
        'points': 500,
        'stock': 15,
        'category': 'voucher',
        'image': 'assets/images/voucher_alfa.png',
      },
      {
        'id': '2',
        'name': 'Voucher Indomaret 50k',
        'description': 'Voucher belanja senilai Rp 50.000 berlaku di seluruh Indomaret',
        'points': 500,
        'stock': 12,
        'category': 'voucher',
        'image': 'assets/images/voucher_indo.png',
      },
      {
        'id': '3',
        'name': 'Pupuk Organik 5kg',
        'description': 'Pupuk organik berkualitas tinggi hasil kompos',
        'points': 300,
        'stock': 25,
        'category': 'produk',
        'image': 'assets/images/pupuk.png',
      },
      {
        'id': '4',
        'name': 'Bibit Tanaman',
        'description': 'Paket bibit sayuran organik (tomat, cabai, kangkung)',
        'points': 200,
        'stock': 30,
        'category': 'produk',
        'image': 'assets/images/bibit.png',
      },
      {
        'id': '5',
        'name': 'Tas Belanja Ramah Lingkungan',
        'description': 'Tas belanja reusable berbahan ramah lingkungan',
        'points': 150,
        'stock': 20,
        'category': 'merchandise',
        'image': 'assets/images/tas.png',
      },
      {
        'id': '6',
        'name': 'Botol Minum Stainless',
        'description': 'Botol minum stainless steel 750ml',
        'points': 100,
        'stock': 40,
        'category': 'merchandise',
        'image': 'assets/images/botol.png',
      },
    ];
  }

  // ==================== USER DEPOSITS ====================
  /// Generate dummy deposit history
  static List<Map<String, dynamic>> getDepositHistory(int count) {
    List<Map<String, dynamic>> deposits = [];
    List<String> wasteTypes = ['Organik Basah', 'Organik Kering', 'Campuran'];
    List<String> locations = ['Drop Point 1 (Jl. Kompos No. 1)', 'Drop Point 2 (Jl. Hijau No. 5)'];

    DateTime now = DateTime.now();

    for (int i = 0; i < count; i++) {
      String wasteType = wasteTypes[_random.nextInt(wasteTypes.length)];
      double weight = 0.5 + _random.nextDouble() * 9.5; // 0.5-10 kg
      int points;

      // Kalkulasi poin berdasarkan jenis
      switch (wasteType) {
        case 'Organik Basah':
          points = (weight * 10).toInt();
          break;
        case 'Organik Kering':
          points = (weight * 8).toInt();
          break;
        case 'Campuran':
          points = (weight * 6).toInt();
          break;
        default:
          points = 0;
      }

      deposits.add({
        'id': 'deposit_${now.millisecondsSinceEpoch}_$i',
        'waste_type': wasteType,
        'weight': weight,
        'points': points,
        'location': locations[_random.nextInt(locations.length)],
        'timestamp': now.subtract(Duration(days: i)).toIso8601String(),
        'has_image': _random.nextBool(),
      });
    }

    return deposits;
  }

  // ==================== STATISTICS ====================
  /// Get dashboard statistics
  static Map<String, dynamic> getDashboardStats() {
    return {
      'total_deposits': 245,
      'total_weight': 1234.5,
      'total_points': 12345,
      'total_users': 128,
      'active_alerts': 3,
      'system_uptime': 99.8,
    };
  }

  /// Get user statistics
  static Map<String, dynamic> getUserStats() {
    return {
      'total_deposits': 15,
      'total_weight': 75.5,
      'total_points': 755,
      'points_used': 300,
      'points_available': 455,
      'member_since': DateTime(2026, 3, 1).toIso8601String(),
      'rank': 12,
    };
  }

  // ==================== REDEEM HISTORY ====================
  /// Generate redeem history
  static List<Map<String, dynamic>> getRedeemHistory(int count) {
    List<Map<String, dynamic>> redeems = [];
    final rewards = getRewards();
    DateTime now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final reward = rewards[_random.nextInt(rewards.length)];
      redeems.add({
        'id': 'redeem_${now.millisecondsSinceEpoch}_$i',
        'reward_name': reward['name'],
        'points_used': reward['points'],
        'timestamp': now.subtract(Duration(days: i * 5)).toIso8601String(),
        'voucher_code': 'KOMP-${_random.nextInt(99999).toString().padLeft(5, '0')}',
        'status': 'completed',
      });
    }

    return redeems;
  }
}
