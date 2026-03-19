import 'package:flutter/material.dart';
import '../../utils/mocks/mock_system_status.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

class AdminSystemStatusScreen extends StatefulWidget {
  const AdminSystemStatusScreen({Key? key}) : super(key: key);
  @override
  State<AdminSystemStatusScreen> createState() => _AdminSystemStatusScreenState();
}

class _AdminSystemStatusScreenState extends State<AdminSystemStatusScreen> {
  late SystemStatusData _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    _status = MockSystemStatus.getStatus();
    if (mounted) setState(() => _isLoading = false);
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
            
            const SizedBox(height: 100), // Padding for nav
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        ..._status.sensorStatus.entries.map((e) => _buildMiniStatusCard(e.key, e.value == 'active')),
        ..._status.actuatorStatus.entries.map((e) => _buildMiniStatusCard(e.key, e.value == 'ready')),
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

