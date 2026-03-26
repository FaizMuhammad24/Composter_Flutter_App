import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../constants/app_colors.dart';
import '../../utils/helpers/csv_export_helper.dart';

class AdminHistoryLogScreen extends StatefulWidget {
  const AdminHistoryLogScreen({Key? key}) : super(key: key);
  @override
  State<AdminHistoryLogScreen> createState() => _AdminHistoryLogScreenState();
}

class _AdminHistoryLogScreenState extends State<AdminHistoryLogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Exhaust Fan', 'Heater', 'Motor Aduk', 'Pompa EM4', 'Pompa Air'];
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('logs/actuators');
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Histori Log Alat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Export CSV',
            onPressed: () => CsvExportHelper.exportActuatorLogs(context, _tabs[_tabController.index]),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.adminPrimary,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 4,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.orderByChild('actuator').equalTo(_tabs[_tabController.index]).onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.adminPrimary));
                }

                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return _buildEmptyState();
                }

                final Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map;
                final List<Map<String, dynamic>> logs = [];
                
                values.forEach((key, data) {
                  logs.add({
                    'id': key,
                    ...Map<String, dynamic>.from(data as Map),
                  });
                });

                // Sort by unix_time descending
                logs.sort((a, b) => (b['unix_time'] as num).compareTo(a['unix_time'] as num));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(logs[index], index == logs.length - 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat untuk ${_tabs[_tabController.index]}',
            style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> log, bool isLast) {
    final bool isOn = log['status'] == 'ON';
    final DateTime time = DateTime.fromMillisecondsSinceEpoch((log['unix_time'] as num).toInt() * 1000);
    final String timeStr = DateFormat('dd MMM, HH:mm:ss').format(time);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Timeline
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOn ? Colors.green : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOn ? Colors.green : Colors.grey.shade400,
                    width: 2.5,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Accent side bar
                      Container(
                        width: 5,
                        color: isOn ? Colors.green : Colors.grey.shade300,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  _buildStatusBadge(isOn),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                log['reason'] ?? 'Aktivitas Otomatis',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3142),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (log['value'] != null && log['value'] != 0.0)
                                Text(
                                  '📡 Deteksi: ${log['value']}${_getUnit(log['actuator'])}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontFamily: 'Poppins',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isOn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOn ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOn ? 'ON' : 'OFF',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isOn ? Colors.green.shade700 : Colors.grey.shade700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  String _getUnit(String? actuator) {
    if (actuator == 'Heater') return '°C';
    if (actuator == 'Exhaust Fan') return ' ppm';
    if (actuator == 'Pompa Air') return '%';
    if (actuator == 'Pompa EM4') return ' pH';
    return '';
  }
}
