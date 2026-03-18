import 'package:flutter/material.dart';
import '../../utils/mock_system_status.dart';
import '../../constants/app_colors.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('System Status', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.admin,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.admin))
          : RefreshIndicator(
              onRefresh: _refreshStatus,
              color: AppColors.admin,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Health Overview
                    _buildHealthCard(),
                    const SizedBox(height: 24),
                    
                    // Connection & Uptime
                    Row(
                      children: [
                        Expanded(child: _buildInfoCard('Uptime', '${_status.uptime['days']}d ${_status.uptime['hours']}h', Icons.timer_outlined, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInfoCard('WiFi', '${_status.wifiStrength}%', Icons.wifi, Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Connection Section
                    const Text('Konektivitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    const SizedBox(height: 12),
                    _buildStatusTile('ESP32 Status', _status.esp32Status == 'online', _status.esp32Status.toUpperCase()),
                    _buildStatusTile('Last Ping', true, _status.lastPing),
                    const SizedBox(height: 24),

                    // Sensors & Actuators
                    const Text('Status Perangkat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    const SizedBox(height: 12),
                    _buildDeviceStatusGrid(),
                    const SizedBox(height: 24),

                    // Device Info
                    const Text('Informasi Perangkat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    const SizedBox(height: 12),
                    _buildDeviceInfoCard(),
                    const SizedBox(height: 32),
                    
                    // Restart Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRestartDialog(),
                        icon: const Icon(Icons.restart_alt, color: Colors.red),
                        label: const Text('Restart System', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: _status.health / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_status.health > 90 ? Colors.green : Colors.orange),
                ),
              ),
              Text('${_status.health.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Health', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Text(
                  _status.health > 90 ? 'Semua sistem berjalan optimal' : 'Perlu pengecekan ringan',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontFamily: 'Poppins'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins')),
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

  Widget _buildDeviceInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: _status.deviceInfo.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Poppins')),
                Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, fontFamily: 'Poppins')),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restart System?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Tindakan ini akan merestart perangkat ESP32. Pastikan tidak ada proses kritis yang sedang berjalan.', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(fontFamily: 'Poppins'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Restart', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}
