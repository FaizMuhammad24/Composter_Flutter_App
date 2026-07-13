import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../utils/helpers/csv_export_helper.dart';
import '../widgets/sensor_history_toggle.dart';

class AdminCategoryGasScreen extends StatefulWidget {
  const AdminCategoryGasScreen({Key? key}) : super(key: key);
  @override
  State<AdminCategoryGasScreen> createState() => _AdminCategoryGasScreenState();
}

class _AdminCategoryGasScreenState extends State<AdminCategoryGasScreen> {
  bool _isLoading = true;
  List<FlSpot> _spots = [];
  List<Map<String, dynamic>> _logEntries = [];
  double _currentValue = 0.0;
  double _thresholdMax = 500.0;

  bool _isOffline = false;
  bool _isFailed = false;
  DateTime? _lastUpdate;
  Timer? _offlineTimer;

  bool _isDataStale(Map<dynamic, dynamic> data) {
    // Tidak lagi menggunakan unix_time/time string untuk cek staleness
    // karena rentan terhadap perbedaan timezone antara RTC ESP32 dan HP.
    return false;
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
      if (DateTime.now().difference(_lastUpdate!).inSeconds > 20 &&
          !_isOffline) {
        setState(() => _isOffline = true);
      }
    });
  }

  void _listenToFirebase() {
    // 1. Dapatkan Nilai Live
    _rtdbSubLive =
        FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final bool stale = _isDataStale(data);
        final double gasVal = (data['gas'] as num?)?.toDouble() ?? 0.0;
        final bool failed = gasVal == -1.0 || gasVal == -1;
        final thresholds = data['thresholds'] as Map?;
        final gasTh = thresholds?['gas'] as Map?;
        final double thMax = (gasTh?['max'] as num?)?.toDouble() ?? 500.0;

        setState(() {
          _isOffline = stale;
          _isFailed = failed;
          _thresholdMax = thMax;
          if (!stale) _lastUpdate = DateTime.now();
          _currentValue = (stale || failed) ? 0.0 : gasVal;
        });
      }
    });

    // 2. Dapatkan Riwayat (2000 log terakhir)
    _rtdbSubLog = FirebaseDatabase.instance
        .ref('komposter_logs')
        .limitToLast(2000)
        .onValue
        .listen((event) {
      if (mounted) {
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          List<FlSpot> newSpots = [];
          List<Map<String, dynamic>> entries = [];

          final sortedKeys = data.keys.toList()..sort();
          int xIndex = 0;
          for (var key in sortedKeys) {
            final log = Map<dynamic, dynamic>.from(data[key] as Map);
            final gas = (log['gas'] as num?)?.toDouble() ?? 0.0;
            final unix = (log['unix_time'] as num?)?.toInt() ?? 0;
            newSpots.add(FlSpot(xIndex.toDouble(), gas));
            entries.add({
              'time': log['time']?.toString() ?? '-',
              'value': gas,
              'unix_time': unix
            });
            xIndex++;
          }

          setState(() {
            _spots = newSpots;
            _logEntries = entries.reversed.toList();
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

  double _calculateAvg() => _spots.isNotEmpty
      ? _spots.map((e) => e.y).reduce((a, b) => a + b) / _spots.length
      : 0.0;
  double _calculateMax() => _spots.isNotEmpty
      ? _spots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        title: const Text('Monitoring Gas ',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[800], // Dark grey primary
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Ubah Threshold',
            onPressed: _showThresholdDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download CSV',
            onPressed: () =>
                CsvExportHelper.exportSingleSensorLogs(context, 'gas', 'Gas'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.grey[800]))
          : Stack(
              children: [
                SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Live
                        Card(
                          elevation: 4,
                          color: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Konsentrasi Gas Saat Ini',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                            fontFamily: 'Poppins')),
                                    Icon(Icons.cloud,
                                        color: Colors.white, size: 40),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                      _isOffline
                                          ? '-- ppm'
                                          : (_isFailed
                                              ? 'GAGAL'
                                              : '${_currentValue.toStringAsFixed(0)} ppm'),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 44,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins')),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Text(
                                        _isOffline
                                            ? 'Offline'
                                            : (_isFailed
                                                ? 'Gagal'
                                                : (_currentValue <=
                                                        _thresholdMax
                                                    ? 'Normal'
                                                    : 'Bahaya')),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Swipeable History (Grafik / Tabel)
                        SensorHistoryToggle(
                          spots: _spots,
                          logEntries: _logEntries,
                          sensorLabel: 'Gas',
                          unit: ' ppm',
                          color: Colors.grey[800]!,
                          minY: 0,
                          maxY: 1000,
                          thresholdMax: _thresholdMax,
                        ),

                        const SizedBox(height: 20),

                        // Statistik
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Statistik',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins')),
                                const SizedBox(height: 16),
                                _buildStatRow(
                                    'Rata-rata',
                                    _isOffline
                                        ? '-'
                                        : '${_calculateAvg().toStringAsFixed(0)} ppm'),
                                const Divider(),
                                _buildStatRow(
                                    'Tertinggi',
                                    _isOffline
                                        ? '-'
                                        : '${_calculateMax().toStringAsFixed(0)} ppm'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Kalibrasi & Threshold telah dihapus
                      ],
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
          Text(label,
              style: const TextStyle(
                  color: Colors.black54, fontFamily: 'Poppins')),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  void _showThresholdDialog() {
    final TextEditingController maxCtrl =
        TextEditingController(text: _thresholdMax.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Batas Gas',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: maxCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Batas Maksimum ppm'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5)),
            onPressed: () {
              final double? newMax = double.tryParse(maxCtrl.text);
              if (newMax != null) {
                FirebaseDatabase.instance
                    .ref('komposter/thresholds/gas')
                    .update({
                  'max': newMax,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Threshold berhasil diupdate!')));
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
