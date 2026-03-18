import 'dart:math';

class SensorDataPoint {
  final DateTime timestamp;
  final double value;
  final String status;

  SensorDataPoint({
    required this.timestamp,
    required this.value,
    required this.status,
  });
}

class MockSensorHistory {
  static final Random _random = Random();

  static List<SensorDataPoint> getTemperatureHistory(String period) {
    int points = _getPointCount(period);
    return List.generate(points, (i) {
      double value = 52.0 + _random.nextDouble() * 13.0;
      return SensorDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: points - i - 1)),
        value: value,
        status: value > 60 ? 'warning' : 'normal',
      );
    });
  }

  static List<SensorDataPoint> getHumidityHistory(String period) {
    int points = _getPointCount(period);
    return List.generate(points, (i) {
      double value = 20.0 + _random.nextDouble() * 50.0;
      String status = 'normal';
      if (value < 30 || value > 60) status = 'warning';
      return SensorDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: points - i - 1)),
        value: value,
        status: status,
      );
    });
  }

  static List<SensorDataPoint> getPhHistory(String period) {
    int points = _getPointCount(period);
    return List.generate(points, (i) {
      double value = 5.5 + _random.nextDouble() * 3.0;
      String status = 'normal';
      if (value < 6 || value > 8) status = 'warning';
      return SensorDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: points - i - 1)),
        value: value,
        status: status,
      );
    });
  }

  static List<SensorDataPoint> getGasHistory(String period) {
    int points = _getPointCount(period);
    return List.generate(points, (i) {
      double value = 50.0 + _random.nextDouble() * 550.0;
      String status = 'normal';
      if (value > 500) status = 'danger';
      else if (value > 400) status = 'warning';
      return SensorDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: points - i - 1)),
        value: value,
        status: status,
      );
    });
  }

  static int _getPointCount(String period) {
    switch (period) {
      case '7 Hari': return 168;
      case '30 Hari': return 720;
      default: return 24; // 24 Jam
    }
  }
}
