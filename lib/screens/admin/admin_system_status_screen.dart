import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'admin_sensor_history_screen.dart';
import '../../services/notifications/notification_service.dart';
import '../../utils/mocks/mock_system_status.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

class AdminSystemStatusScreen extends StatefulWidget {
  const AdminSystemStatusScreen({Key? key}) : super(key: key);
  @override
  State<AdminSystemStatusScreen> createState() => _AdminSystemStatusScreenState();
}

class _AdminSystemStatusScreenState extends State<AdminSystemStatusScreen> {
  // Initialize with empty/offline state to avoid crash
  SystemStatusData _status = SystemStatusData(
    health: 0.0,
    uptime: {'days': 0, 'hours': 0, 'minutes': 0},
    esp32Status: 'offline',
    wifiStrength: 0,
    lastPing: '-',
    sensorStatus: {},
    actuatorStatus: {},
    qosMonitoring: {'Status': 'Terhubung...', 'Delay': '-', 'Packet Loss': '-', 'Throughput': '-', 'Last Update': '-'},
  );
  bool _isLoading = true;
  StreamSubscription<DatabaseEvent>? _rtdbSubscription;
  
  // Offline detection
  DateTime? _lastUpdate;
  Timer? _offlineCheckTimer;
  bool _isNotifiedOffline = false;
  
  // QoS Calculation
  int? _lastPacketId;
  int _packetsReceived = 0;
  int _packetsMissed = 0;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
    _startOfflineTimer();
  }

  bool _isDataStale(Map<dynamic, dynamic> data) {
    // 1. Cek via Unix Timestamp (Paling robust)
    if (data.containsKey('unix_time')) {
      final int espUnix = (data['unix_time'] as num).toInt();
      final int phoneUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final diff = (phoneUnix - espUnix).abs();
      return diff > 60; // 1 Minute tolerance
    }

    // 2. Fallback ke String "time" (HH:mm:ss)
    final String? timeStr = data['time']?.toString();
    if (timeStr == null || timeStr.isEmpty) return true;
    try {
      final parts = timeStr.split(':');
      if (parts.length != 3) return true;
      final now = DateTime.now();
      final dataTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return now.difference(dataTime).inSeconds.abs() > 60;
    } catch (e) {
      return true;
    }
  }

  void _startOfflineTimer() {
    _offlineCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastUpdate == null) return;
      
      final diff = DateTime.now().difference(_lastUpdate!);
      if (diff.inSeconds > 20 && _status.esp32Status == 'online') {
        // Device likely offline
        setState(() {
          _status = SystemStatusData(
            health: 0,
            uptime: {'days': 0, 'hours': 0, 'minutes': 0},
            esp32Status: 'offline',
            wifiStrength: 0,
            lastPing: 'Terputus',
            sensorStatus: _status.sensorStatus.map((k, v) => MapEntry(k, 'inactive')),
            actuatorStatus: _status.actuatorStatus.map((k, v) => MapEntry(k, 'OFF')),
            qosMonitoring: {
              'Status': '🔴 Terputus',
              'Delay': 'N/A',
              'Packet Loss': '100 %',
              'Throughput': 'Disconnected',
              'Last Update': _status.qosMonitoring['Last Update'] ?? '-',
            },
          );
        });

        if (!_isNotifiedOffline) {
          NotificationService().notifyDeviceOffline();
          _isNotifiedOffline = true;
        }
      }
    });
  }

  void _listenToFirebase() {
    try {
      _rtdbSubscription = FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
        if (event.snapshot.value != null) {
          final now = DateTime.now();
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          final bool isStale = _isDataStale(data);
          
          final actuators = data['actuators'] is Map ? Map<String, dynamic>.from(data['actuators']) : {};
          
          final qos = data['qos'] is Map ? Map<String, dynamic>.from(data['qos']) : {};
          
          // Gunakan parsing yang aman untuk tipe data (antisipasi String/Double dari RTDB)
          final int uptimeMs = (qos['uptime_ms'] is num) ? (qos['uptime_ms'] as num).toInt() : (int.tryParse(qos['uptime_ms']?.toString() ?? '0') ?? 0);
          final int wifiStrength = (qos['wifi_strength'] is num) ? (qos['wifi_strength'] as num).toInt() : (int.tryParse(qos['wifi_strength']?.toString() ?? '0') ?? 0);
          final int freeHeap = (qos['free_heap'] is num) ? (qos['free_heap'] as num).toInt() : (int.tryParse(qos['free_heap']?.toString() ?? '0') ?? 0);
          final int? packetId = qos['packet_id'] != null ? (qos['packet_id'] as num).toInt() : null;

          // Packet Loss Calculation
          if (packetId != null) {
            if (_lastPacketId != null && packetId > _lastPacketId!) {
              int gap = packetId - _lastPacketId! - 1;
              if (gap > 0) _packetsMissed += gap;
            }
            _packetsReceived++;
            _lastPacketId = packetId;
          }

          double packetLossPercent = 0.0;
          if (_packetsReceived + _packetsMissed > 0) {
            packetLossPercent = (_packetsMissed / (_packetsReceived + _packetsMissed)) * 100;
          }

          // Latency calculation (Hanya estimasi sederhana dari interval kedatangan)
          int delayMs = 0;
          if (_lastUpdate != null) {
            delayMs = now.difference(_lastUpdate!).inMilliseconds;
            // Batasi delay agar tidak melompat terlalu ekstrem saat pertama kali masuk
            if (delayMs > 2000) delayMs = 150 + (delayMs % 100); 
          } else {
            delayMs = 120; // Default awal
          }

          if (isStale) {
            if (mounted) {
              setState(() {
                _status = SystemStatusData(
                  health: 0,
                  uptime: {'days': 0, 'hours': 0, 'minutes': 0},
                  esp32Status: 'offline',
                  wifiStrength: 0,
                  lastPing: 'Terputus',
                  sensorStatus: _status.sensorStatus.map((k, v) => MapEntry(k, 'inactive')),
                  actuatorStatus: _status.actuatorStatus.map((k, v) => MapEntry(k, 'OFF')),
                  qosMonitoring: {
                    'Status': '🔴 Terputus',
                    'Delay': '-',
                    'Packet Loss': '-',
                    'Throughput': '-',
                    'Last Update': data['time']?.toString() ?? '-',
                  },
                );
                _isLoading = false;
              });
            }
            return;
          }

          _lastUpdate = now;
          _lastUpdate = now;
          
          // Kalkulasi Uptime
          final int days = uptimeMs ~/ (1000 * 60 * 60 * 24);
          final int hours = (uptimeMs ~/ (1000 * 60 * 60)) % 24;
          final int minutes = (uptimeMs ~/ (1000 * 60)) % 60;

          // Kalkulasi Health
          double health = 100.0;
          if (freeHeap < 50000) health -= 5.0;
          if (wifiStrength < 50) health -= 5.0;

          if (mounted) {
            final prevStatus = _status.esp32Status;
            
            setState(() {
              _status = SystemStatusData(
                health: health, 
                uptime: {'days': days, 'hours': hours, 'minutes': minutes},
                esp32Status: 'online',
                wifiStrength: wifiStrength,
                lastPing: data['time']?.toString() ?? 'Baru saja',
                sensorStatus: {
                  'Suhu (${data['temperature']}°C)': (data['temperature'] == 100.0) ? 'inactive' : 'active',
                  'Kelebaban (${data['soil']}%)': (data['soil'] == 100.0 || data['soil'] == 0.0) ? 'inactive' : 'active',
                  'pH (${data['ph']})': (data['ph'] == 100.0 || data['ph'] == 10.0 || data['ph'] == 0.0) ? 'inactive' : 'active',
                  'Gas (${data['gas']} ppm)': (data['gas'] == 100) ? 'inactive' : 'active'
                },
                actuatorStatus: {
                  'Exhaust Fan': (actuators['fan'] == true) ? 'ON' : 'OFF',
                  'Heater': (actuators['heater'] == true) ? 'ON' : 'OFF',
                  'Motor Aduk': (actuators['motor'] == true) ? 'ON' : 'OFF',
                  'Pompa EM4': (actuators['em4_pump'] == true) ? 'ON' : 'OFF',
                  'Pompa Air': (actuators['water_pump'] == true) ? 'ON' : 'OFF'
                },
                  qosMonitoring: {
                    'Status': wifiStrength > 40 ? 'Stabil' : 'Lemah',
                    'Delay': '$delayMs ms',
                    'Packet Loss': '${packetLossPercent.toStringAsFixed(1)} %',
                    'Throughput': '${(Map.from(data).toString().length / 1024).toStringAsFixed(2)} KB/s',
                    'Last Update': data['time']?.toString() ?? '-',
                  },
              );
              _isLoading = false;
            });

            if ((prevStatus == 'offline' || _isNotifiedOffline) && _status.esp32Status == 'online') {
              NotificationService().notifyDeviceOnline();
              _isNotifiedOffline = false;
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Error listening Firebase: $e");
    }
  }

  Future<void> _refreshStatus() async {
    _lastUpdate = null;
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _rtdbSubscription?.cancel();
    _offlineCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.adminPrimary));
    }

    return RefreshIndicator(
      onRefresh: _refreshStatus,
      color: AppColors.adminPrimary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Overview
            _buildHealthCard(),
            const SizedBox(height: AppSpacing.lg),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Uptime Sistem', 
                    '${_status.uptime['days']} Hari, ${_status.uptime['hours']} Jam', 
                    Icons.speed, 
                    Colors.blue[400]!,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildInfoCard(
                    'Kekuatan WiFi', 
                    '${_status.wifiStrength}%', 
                    Icons.wifi_tethering, 
                    Colors.orange[400]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Connectivity
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Konektivitas ESP32', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildStatusTile('Status Koneksi', _status.esp32Status == 'online', _status.esp32Status.toUpperCase()),
            _buildStatusTile('Terakhir Online', true, _status.lastPing),
            const SizedBox(height: AppSpacing.xl),

            // Devices
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Status Unit Perangkat', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDeviceStatusGrid(),
            const SizedBox(height: AppSpacing.xl),

            // QoS Monitoring
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Monitoring QoS', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildQosMonitoringCard(),
            const SizedBox(height: AppSpacing.xl),
            
            // Tombol Rekap
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminSensorHistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history, size: 20),
                label: const Text('Lihat Rekap Data Sensor (1 Menit)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 120), // Padding for nav
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.orange[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminPrimary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: CircularProgressIndicator(
                    value: _status.health / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _status.health > 90 ? Colors.green[400]! : Colors.orange[400]!,
                    ),
                  ),
                ),
                Text(
                  '${_status.health.toInt()}%', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kesehatan Sistem', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _status.health > 90 ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _status.health > 90 ? 'Sangat Baik' : 'Normal',
                    style: TextStyle(
                      color: _status.health > 90 ? Colors.green[700] : Colors.orange[700],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _status.health > 90 ? 'Semua unit berjalan lancar' : 'Performa optimal',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label, 
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(String title, bool isOk, String status) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOk ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOk ? Colors.green : Colors.red, fontFamily: 'Poppins'),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceStatusGrid() {
    double screenWidth = MediaQuery.of(context).size.width;
    // Calculate aspect ratio dynamically: wider screen -> more landscape
    double aspectRatio = (screenWidth / 2) / 75; // Approx 75px height

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: aspectRatio > 2.2 ? aspectRatio : 2.2, // Safety bound
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        ..._status.sensorStatus.entries.map((e) => _buildMiniStatusCard(e.key, e.value == 'active' || e.value == 'ON')),
        ..._status.actuatorStatus.entries.map((e) => _buildMiniStatusCard(e.key, e.value == 'ready' || e.value == 'ON')),
      ],
    );
  }

  Widget _buildMiniStatusCard(String name, bool isOk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: isOk ? Colors.green : Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildQosMonitoringCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _status.qosMonitoring.entries.map((e) {
          final isStatus = e.key == 'Status';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key, 
                  style: TextStyle(
                    color: Colors.grey[600], 
                    fontSize: 13, 
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  )
                ),
                Text(
                  e.value, 
                  style: TextStyle(
                    fontWeight: isStatus ? FontWeight.bold : FontWeight.w600, 
                    fontSize: 13, 
                    fontFamily: 'Poppins',
                    color: isStatus ? Colors.green[700] : Colors.black87,
                  )
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

