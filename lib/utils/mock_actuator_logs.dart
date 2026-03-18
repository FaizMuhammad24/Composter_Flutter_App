import 'dart:math';

class ActuatorLog {
  final DateTime timestamp;
  final String status;
  final String duration;
  final String? sensorValue;
  final String reason;
  final String actuatorName;

  ActuatorLog({
    required this.timestamp,
    required this.status,
    required this.duration,
    this.sensorValue,
    required this.reason,
    required this.actuatorName,
  });
}

class MockActuatorLogs {
  static final Random _random = Random();

  static List<ActuatorLog> getExhaustFanLogs() => _generateLogs('Exhaust Fan', 'Gas', 'ppm', 500, 'tinggi');
  static List<ActuatorLog> getHeaterLogs() => _generateLogs('Heater', 'Suhu', '°C', 60, 'rendah');
  static List<ActuatorLog> getPompaFLMLogs() => _generateLogs('Pompa FLM', 'pH', '', 6, 'tidak normal');
  static List<ActuatorLog> getPompaAirLogs() => _generateLogs('Pompa Air', 'Kelembaban', '%', 30, 'rendah');
  
  static List<ActuatorLog> getMotorAdukLogs() {
    return List.generate(20, (i) {
      bool isOn = i % 2 == 0;
      return ActuatorLog(
        timestamp: DateTime.now().subtract(Duration(hours: i * 4)),
        status: isOn ? 'ON' : 'OFF',
        duration: '30 min',
        reason: isOn ? 'Jadwal otomatis' : 'Selesai pengadukan',
        actuatorName: 'Motor Aduk',
      );
    });
  }

  static List<ActuatorLog> _generateLogs(String name, String sensor, String unit, double threshold, String trigger) {
    return List.generate(20, (i) {
      bool isOn = i % 2 == 0;
      double value = isOn ? (threshold + (trigger == 'tinggi' ? 20 : -5)) : (threshold + (trigger == 'tinggi' ? -50 : 10));
      return ActuatorLog(
        timestamp: DateTime.now().subtract(Duration(hours: i * 2)),
        status: isOn ? 'ON' : 'OFF',
        duration: '${10 + _random.nextInt(20)} min',
        sensorValue: '${value.toStringAsFixed(1)} $unit',
        reason: isOn ? '$sensor $trigger' : '$sensor normal',
        actuatorName: name,
      );
    });
  }
}
