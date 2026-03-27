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
  int _selectedFilter = 0; // 0=Jam, 1=Hari, 2=Minggu
  final List<String> _filterLabels = ['Per Jam', 'Per Hari', 'Per Minggu'];

  int get _logLimit {
    switch (_selectedFilter) {
      case 0: return 60;    // ~1 jam
      case 1: return 1440;  // ~1 hari
      case 2: return 10080; // ~1 minggu
      default: return 60;
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    await CsvExportHelper.exportQosLogs(context);
    if (mounted) setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekap Data QoS', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
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
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.adminPrimary.withOpacity(0.05),
            child: Row(
              children: List.generate(3, (index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabels[index], style: TextStyle(
                      fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.adminPrimary,
                    )),
                    selected: isSelected,
                    selectedColor: AppColors.adminPrimary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppColors.adminPrimary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedFilter = index);
                    },
                  ),
                );
              }),
            ),
          ),
          // Content
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _logsRef.limitToLast(_logLimit).onValue,
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
                List<MapEntry<dynamic, dynamic>> sortedLogs = data.entries.toList()
                  ..sort((a, b) => b.key.toString().compareTo(a.key.toString()));

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  physics: const BouncingScrollPhysics(),
                  itemCount: sortedLogs.length,
                  itemBuilder: (context, index) {
                    final logData = Map<String, dynamic>.from(sortedLogs[index].value as Map);
                    return _buildQosCard(logData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQosCard(Map<String, dynamic> log) {
    final timeStr = log['time']?.toString() ?? '-';
    final qos = log['qos'] is Map ? Map<String, dynamic>.from(log['qos']) : null;
    final int? wifi = qos?['wifi_strength'] is num ? (qos?['wifi_strength'] as num).toInt() : (int.tryParse(qos?['wifi_strength']?.toString() ?? ''));
    final int? heap = qos?['free_heap'] is num ? (qos?['free_heap'] as num).toInt() : null;
    final int? uptime = qos?['uptime_ms'] is num ? (qos?['uptime_ms'] as num).toInt() : null;
    final int? packetId = qos?['packet_id'] is num ? (qos?['packet_id'] as num).toInt() : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_filled, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(timeStr, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
                  ],
                ),
                if (wifi != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (wifi > 60 ? Colors.green : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi, size: 12, color: wifi > 60 ? Colors.green : Colors.orange),
                        const SizedBox(width: 4),
                        Text('$wifi%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: wifi > 60 ? Colors.green[700] : Colors.orange[700])),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // QoS Metrics Grid
            Row(
              children: [
                if (wifi != null) Expanded(child: _qosMetric(Icons.wifi, 'WiFi', '$wifi%', wifi > 60 ? Colors.green : Colors.orange)),
                if (heap != null) Expanded(child: _qosMetric(Icons.memory, 'RAM', '${(heap / 1024).toStringAsFixed(0)} KB', Colors.blue)),
                if (uptime != null) Expanded(child: _qosMetric(Icons.timer, 'Uptime', _formatUptime(uptime), Colors.purple)),
                if (packetId != null) Expanded(child: _qosMetric(Icons.tag, 'Packet', '#$packetId', Colors.teal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qosMetric(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontFamily: 'Poppins')),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.grey[800])),
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

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LoadingShimmer(width: double.infinity, height: 90, borderRadius: BorderRadius.circular(14)),
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
          Text('Belum ada data QoS.', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Menunggu ESP32 mengirim log baru.', style: TextStyle(fontSize: 13, color: Colors.grey[400], fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
