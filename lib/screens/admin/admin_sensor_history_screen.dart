import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../utils/helpers/csv_export_helper.dart';

class AdminSensorHistoryScreen extends StatefulWidget {
  const AdminSensorHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AdminSensorHistoryScreen> createState() => _AdminSensorHistoryScreenState();
}

class _AdminSensorHistoryScreenState extends State<AdminSensorHistoryScreen> {
  final DatabaseReference _logsRef = FirebaseDatabase.instance.ref('komposter_logs');
  bool _isExporting = false;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    await CsvExportHelper.exportKomposterLogs(context);
    if (mounted) setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekap Riwayat (1 Menit)', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Download CSV',
                  onPressed: _exportData,
                ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _logsRef.limitToLast(100).onValue, // Ambil 100 log terbaru
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontFamily: 'Poppins')));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _buildEmptyState();
          }

          final data = snapshot.data!.snapshot.value as Map;
          
          // Convert ke List dan sort dari yang terbaru ke terlama
          List<MapEntry<dynamic, dynamic>> sortedLogs = data.entries.toList()
            ..sort((a, b) => b.key.toString().compareTo(a.key.toString()));

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            physics: const BouncingScrollPhysics(),
            itemCount: sortedLogs.length,
            itemBuilder: (context, index) {
              final logData = Map<String, dynamic>.from(sortedLogs[index].value as Map);
              return _buildLogCard(logData, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, int index) {
    // Format nilai dengan presisi jika double
    final tempRaw = log['temperature'];
    final tempStr = (tempRaw is double) ? tempRaw.toStringAsFixed(1) : tempRaw.toString();
    
    final phRaw = log['ph'];
    final phStr = (phRaw is double) ? phRaw.toStringAsFixed(1) : phRaw.toString();

    final gas = log['gas']?.toString() ?? '-';
    final soil = log['soil']?.toString() ?? '-';
    final timeStr = log['time']?.toString() ?? 'Pukul ?';

    // QoS Data (Baru)
    final int? wifi = log['wifi'] is int ? log['wifi'] as int : null;
    final int? heap = log['heap'] is int ? log['heap'] as int : null;
    final int? uptime = log['uptime'] is int ? log['uptime'] as int : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Header (Waktu & WiFi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_filled, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(timeStr, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
                  ],
                ),
                if (wifi != null)
                  Row(
                    children: [
                      Icon(Icons.wifi, size: 14, color: wifi > 60 ? Colors.green : Colors.orange),
                      const SizedBox(width: 4),
                      Text('$wifi%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    ],
                  ),
              ],
            ),
            const Divider(height: 20),
            
            // Sensor Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.thermostat, Colors.orange, 'Suhu', '$tempStr°C'),
                _buildStatItem(Icons.cloud, Colors.grey[600]!, 'Gas', '$gas ppm'),
                _buildStatItem(Icons.water_drop, Colors.blue, 'Tanah', '$soil%'),
                _buildStatItem(Icons.science, Colors.purple, 'pH', phStr),
              ],
            ),
            
            // QoS Section (Heap & Uptime)
            if (heap != null || uptime != null || wifi != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (wifi != null)
                      _buildQosLabel(Icons.wifi, 'WiFi: $wifi%'),
                    if (heap != null)
                      _buildQosLabel(Icons.memory, 'RAM: ${(heap / 1024).toStringAsFixed(0)} KB'),
                    if (uptime != null)
                      _buildQosLabel(Icons.timer, 'Up: ${_formatUptime(uptime)}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQosLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.blueGrey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
      ],
    );
  }

  String _formatUptime(int ms) {
    if (ms < 1000) return '0s';
    final sec = (ms / 1000).floor();
    final min = (sec / 60).floor();
    final h = (min / 60).floor();
    if (h > 0) return '${h}h ${min % 60}m';
    if (min > 0) return '${min}m ${sec % 60}s';
    return '${sec}s';
  }

  Widget _buildStatItem(IconData icon, Color color, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'Poppins')),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LoadingShimmer(width: double.infinity, height: 110, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat data.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: 'Poppins', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Menunggu ESP32 mengirim log baru (tiap 1 menit).',
            style: TextStyle(fontSize: 13, color: Colors.grey[400], fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}
