class SystemStatusData {
  final double health;
  final Map<String, int> uptime;
  final String esp32Status;
  final int wifiStrength;
  final String lastPing;
  final Map<String, String> sensorStatus;
  final Map<String, String> actuatorStatus;
  final Map<String, String> qosMonitoring;

  SystemStatusData({
    required this.health,
    required this.uptime,
    required this.esp32Status,
    required this.wifiStrength,
    required this.lastPing,
    required this.sensorStatus,
    required this.actuatorStatus,
    required this.qosMonitoring,
  });
}

class MockSystemStatus {
  static SystemStatusData getStatus() {
    return SystemStatusData(
      health: 98.5,
      uptime: {'days': 15, 'hours': 8, 'minutes': 42},
      esp32Status: 'online',
      wifiStrength: 85,
      lastPing: '2 detik lalu',
      sensorStatus: {
        'Suhu': 'active',
        'Kelembaban': 'active',
        'pH': 'active',
        'Gas': 'active'
      },
      actuatorStatus: {
        'Exhaust Fan': 'ready',
        'Heater': 'ready',
        'Motor Aduk': 'ready',
        'Pompa EM4': 'ready',
        'Pompa Air': 'ready'
      },
      qosMonitoring: {
        'Status': '🟢 Stabil',
        'Delay': '120 ms',
        'Packet Loss': '1.2 %',
        'Throughput': '12 KB/s',
        'Last Update': '10:32',
      },
    );
  }
}
