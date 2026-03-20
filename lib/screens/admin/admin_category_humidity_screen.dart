import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../utils/helpers/csv_export_helper.dart';

class AdminCategoryHumidityScreen extends StatefulWidget {
  const AdminCategoryHumidityScreen({Key? key}) : super(key: key);
  @override
  State<AdminCategoryHumidityScreen> createState() => _AdminCategoryHumidityScreenState();
}

class _AdminCategoryHumidityScreenState extends State<AdminCategoryHumidityScreen> {
  bool _isLoading = true;
  List<FlSpot> _spots = [];
  double _currentValue = 0.0;
  bool _pumpStatus = false;
  bool _isOffline = false;
  bool _isFailed = false;
  DateTime? _lastUpdate;
  Timer? _offlineTimer;

  bool _isDataStale(Map<dynamic, dynamic> data) {
    if (data.containsKey('unix_time')) {
      final int espUnix = (data['unix_time'] as num).toInt();
      final int phoneUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final diff = (phoneUnix - espUnix).abs();
      return diff > 120;
    }
    final String? timeStr = data['time']?.toString();
    if (timeStr == null || timeStr.isEmpty) return true;
    try {
      final parts = timeStr.split(':');
      if (parts.length != 3) return true;
      final now = DateTime.now();
      final dataTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return now.difference(dataTime).inSeconds.abs() > 120;
    } catch (e) {
      return true;
    }
  }
  
  StreamSubscription? _rtdbSubLog;
  StreamSubscription? _rtdbSubLive;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
    _startOfflineTimer();
  }

  void _startOfflineTimer() {
    _offlineTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastUpdate == null) return;
      if (DateTime.now().difference(_lastUpdate!).inSeconds > 20 && !_isOffline) {
        setState(() => _isOffline = true);
      }
    });
  }

  void _listenToFirebase() {
    // 1. Dapatkan Nilai Live
    _rtdbSubLive = FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final bool stale = _isDataStale(data);
        final double soilVal = (data['soil'] as num?)?.toDouble() ?? 0.0;
        final bool failed = soilVal == 100.0 || soilVal == 0.0;
        
        setState(() {
          _isOffline = stale;
          _isFailed = failed;
          if (!stale) _lastUpdate = DateTime.now();
          _currentValue = (stale || failed) ? 0.0 : soilVal;
          final actuators = data['actuators'] as Map? ?? {};
          _pumpStatus = !stale && !failed && actuators['water_pump'] == true;
        });
      }
    });

    // 2. Dapatkan Riwayat (100 log terakhir)
    _rtdbSubLog = FirebaseDatabase.instance.ref('komposter_logs').limitToLast(100).onValue.listen((event) {
      if (mounted) {
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          List<FlSpot> newSpots = [];
          
          final sortedKeys = data.keys.toList()..sort();
          int xIndex = 0;
          for (var key in sortedKeys) {
            final log = Map<dynamic, dynamic>.from(data[key] as Map);
            final soil = (log['soil'] as num?)?.toDouble() ?? 0.0;
            newSpots.add(FlSpot(xIndex.toDouble(), soil));
            xIndex++;
          }

          setState(() {
            _spots = newSpots;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _rtdbSubLog?.cancel();
    _rtdbSubLive?.cancel();
    _offlineTimer?.cancel();
    super.dispose();
  }

  double _calculateAvg() => _spots.isNotEmpty ? _spots.map((e) => e.y).reduce((a, b) => a + b) / _spots.length : 0.0;
  double _calculateMax() => _spots.isNotEmpty ? _spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text('Kelembaban Tanah', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00B4D8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download CSV',
            onPressed: () => CsvExportHelper.exportKomposterLogs(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8)))
          : Stack(
              children: [
                Opacity(
                  opacity: (_isOffline || _isFailed) ? 0.4 : 1.0,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Live
                        Card(
                          elevation: 4,
                          color: const Color(0xFF00B4D8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Kelembaban Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Poppins')),
                                    Icon(Icons.water_drop, color: Colors.white, size: 40),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(_isOffline ? '--%' : (_isFailed ? 'GAGAL' : '${_currentValue.toStringAsFixed(0)}%'), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Pompa Air', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                                          const SizedBox(height: 4),
                                          Text(_isOffline ? 'TERPUTUS' : (_pumpStatus ? 'AKTIF (ON)' : 'MATI (OFF)'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Text(
                                        _isOffline ? 'Offline' : (_isFailed ? 'Gagal' : (_currentValue >= 30 ? 'Normal' : 'Kering')),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text('Historis Perubahan Kelembaban', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                        const SizedBox(height: 16),

                        // Chart Line
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Grafik Kelembaban (100 Log)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 200,
                                  child: _spots.isEmpty ? const Center(child: Text('Belum ada data')) : LineChart(
                                    LineChartData(
                                      minY: 0, maxY: 100,
                                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                                      titlesData: FlTitlesData(
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      extraLinesData: ExtraLinesData(
                                        horizontalLines: [
                                          HorizontalLine(y: 30, color: Colors.red.withOpacity(0.5), strokeWidth: 2, dashArray: [5, 5], label: HorizontalLineLabel(show: true, labelResolver: (line) => 'Batas Kering', style: const TextStyle(color: Colors.red, fontSize: 10))),
                                        ],
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _spots,
                                          isCurved: true,
                                          color: const Color(0xFF00B4D8),
                                          barWidth: 3,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [const Color(0xFF00B4D8).withOpacity(0.3), const Color(0xFF00B4D8).withOpacity(0.0)],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Statistik
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Statistik', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                const SizedBox(height: 16),
                                _buildStatRow('Rata-rata', _isOffline ? '-' : '${_calculateAvg().toStringAsFixed(1)}%'),
                                const Divider(),
                                _buildStatRow('Tertinggi', _isOffline ? '-' : '${_calculateMax().toStringAsFixed(1)}%'),
                                const Divider(),
                                _buildStatRow('Pompa Sedang Aktif', _isOffline ? 'Terputus' : (_pumpStatus ? 'Ya' : 'Tidak')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isOffline)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sensor Terputus (Offline)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isFailed && !_isOffline)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'SENSOR TIDAK TERBACA',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontFamily: 'Poppins')),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
