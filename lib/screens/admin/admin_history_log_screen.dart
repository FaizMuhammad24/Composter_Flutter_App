import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/mock_actuator_logs.dart';
import '../../constants/app_colors.dart';

class AdminHistoryLogScreen extends StatefulWidget {
  const AdminHistoryLogScreen({Key? key}) : super(key: key);
  @override
  State<AdminHistoryLogScreen> createState() => _AdminHistoryLogScreenState();
}

class _AdminHistoryLogScreenState extends State<AdminHistoryLogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Exhaust Fan', 'Heater', 'Motor Aduk', 'Pompa EM4', 'Pompa Air'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.adminBg,
      child: Column(
        children: [
          Container(
            color: AppColors.adminPrimary,
            child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Poppins'),
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLogList(MockActuatorLogs.getExhaustFanLogs()),
              _buildLogList(MockActuatorLogs.getHeaterLogs()),
              _buildLogList(MockActuatorLogs.getMotorAdukLogs()),
              _buildLogList(MockActuatorLogs.getPompaEM4Logs()),
              _buildLogList(MockActuatorLogs.getPompaAirLogs()),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLogList(List<ActuatorLog> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text('Tidak ada data log', style: TextStyle(fontFamily: 'Poppins')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isLast = index == logs.length - 1;
        final isOn = log.status == 'ON';

        return IntrinsicHeight(
          child: Row(
            children: [
              // Timeline line and circle
              Column(
                children: [
                  Container(
                    width: 2,
                    height: 20,
                    color: index == 0 ? Colors.transparent : Colors.grey[400],
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isOn ? Colors.green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isOn ? Colors.green : Colors.grey, width: 2),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast ? Colors.transparent : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Log content card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm:ss').format(log.timestamp),
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOn ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOn ? Colors.green : Colors.grey[600],
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log.reason,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins'),
                      ),
                      if (log.sensorValue != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Deteksi Sensor: ${log.sensorValue}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'Poppins'),
                        ),
                      ],
                      if (isOn) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Durasi: ${log.duration}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
