import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/helpers/screen_utils.dart';
import '../../utils/mocks/mock_data.dart';
import '../../models/sensor_data_model.dart';
import '../../widgets/cards/sensor_card.dart';
import '../../widgets/common/loading_shimmer.dart';
import 'admin_category_temperature_screen.dart';
import 'admin_category_humidity_screen.dart';
import 'admin_category_ph_screen.dart';
import 'admin_category_gas_screen.dart';
import 'admin_history_log_screen.dart';
import '../../utils/mocks/mock_actuator_logs.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Timer? _refreshTimer;
  SensorDataModel? _sensorData;
  Map<String, dynamic> _actuatorStatus = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Load data from mock service
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final sensorDataJson = MockData.getSensorData();
    // final alertsJson = MockData.getAlerts(3); // Not used in the new design

    setState(() {
      _sensorData = SensorDataModel.fromJson(sensorDataJson);
      _actuatorStatus = MockData.getActuatorStatus();
      _isLoading = false;
    });

    _animationController.forward();
  }

  // Auto refresh every 5 seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final sensorDataJson = MockData.getSensorData();
        setState(() {
          _sensorData = SensorDataModel.fromJson(sensorDataJson);
          _actuatorStatus = MockData.getActuatorStatus();
        });
      }
    });
  }

  // Count active actuators
  int _countActiveActuators() {
    int count = 0;
    _actuatorStatus.forEach((key, value) {
      if (key != 'timestamp' && value == true) count++;
    });
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? _buildLoadingState() : _buildContent();
  }



  // Loading state with shimmer
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ScreenUtils.getSensorGridCount(context),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: const [
              SensorCardShimmer(),
              SensorCardShimmer(),
              SensorCardShimmer(),
              SensorCardShimmer(),
            ],
          ),
        ],
      ),
    );
  }

  // Main content
  Widget _buildContent() {
    if (_sensorData == null) return const SizedBox();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF9C4), // Soft yellow top
            AppColors.adminBg, // Cream bottom
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.adminPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Monitoring Sensor Real-time'),
              const SizedBox(height: AppSpacing.md),
              _buildSensorGrid(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(
                'Histori Log Alat', 
                trailing: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminHistoryLogScreen()),
                  ),
                  child: const Text(
                    'Lihat Selengkapnya',
                    style: TextStyle(
                      color: AppColors.adminPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildHorizontalHistory(),
              const SizedBox(height: 100), // Bottom padding for nav
            ],
          ),
        ),
      ),
    );
  }



  // Hero Card like User Dashboard
  Widget _buildHeroCard() {
    final stats = MockData.getDashboardStats();
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Icon(
              Icons.admin_panel_settings,
              size: 70,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel Kendali Admin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Text(
                  'Monitoring Sistem',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildHeroStatCard('⚠️', stats['active_alerts'].toString(), 'Total Alert'),
                    const SizedBox(width: 10),
                    _buildHeroStatCard('🔌', '${_countActiveActuators()}/5', 'Alat Aktif'),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                             Text(timeStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                             const SizedBox(height: 2),
                             Text(DateFormat('EEE').format(now), style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'Poppins')),
                             Text(DateFormat('d MMM').format(now), style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Symmetrical Sensor Grid (2x2 layout)
  Widget _buildSensorGrid() {
    if (_sensorData == null) return const SizedBox();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSuhuCard()),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildKelembabanCard()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildPhCard()),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildGasCard()),
          ],
        ),
      ],
    );
  }

  // Horizontal History Log (Actuator Style)
  Widget _buildHorizontalHistory() {
    final List<ActuatorLog> latestLogs = [
      MockActuatorLogs.getExhaustFanLogs().first,
      MockActuatorLogs.getHeaterLogs().first,
      MockActuatorLogs.getMotorAdukLogs().first,
      MockActuatorLogs.getPompaEM4Logs().first,
      MockActuatorLogs.getPompaAirLogs().first,
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: latestLogs.length,
        itemBuilder: (context, index) {
          final log = latestLogs[index];
          final bool isOn = log.status == 'ON';
          
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOn ? AppColors.adminPrimary : Colors.grey[400],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.settings_remote, size: 14, color: Colors.white),
                      Text(
                        log.actuatorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHistoryDetailRow(Icons.calendar_today, DateFormat('dd MMM yyyy, HH:mm:ss').format(log.timestamp), Colors.blue),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.power_settings_new, size: 14, color: isOn ? Colors.green : Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Poppins'),
                          ),
                          Text(
                            log.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOn ? Colors.green : Colors.red,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Penyebab: ${log.reason}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryDetailRow(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSuhuCard() {
    return SensorCard(
      title: 'Suhu',
      value: _sensorData!.temperature.toStringAsFixed(1),
      unit: '°C',
      status: _sensorData!.temperatureStatus,
      valuePercent: (_sensorData!.temperature - 30) / (80 - 30),
      actuatorInfo: 'Heater: ${_actuatorStatus['heater'] == true ? 'ON' : 'OFF'}',
      icon: Icons.thermostat,
      color: AppColors.temperature,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCategoryTemperatureScreen()),
      ),
    );
  }

  Widget _buildKelembabanCard() {
    return SensorCard(
      title: 'Kelembaban',
      value: _sensorData!.humidity.toStringAsFixed(1),
      unit: '%',
      status: _sensorData!.humidityStatus,
      valuePercent: _sensorData!.humidity / 100,
      actuatorInfo: 'Pompa Air: ${_actuatorStatus['pompa_air'] == true ? 'ON' : 'OFF'}',
      icon: Icons.water_drop,
      color: AppColors.humidity,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCategoryHumidityScreen()),
      ),
    );
  }

  Widget _buildPhCard() {
    return SensorCard(
      title: 'pH',
      value: _sensorData!.ph.toStringAsFixed(1),
      unit: '',
      status: _sensorData!.phStatus,
      valuePercent: _sensorData!.ph / 14,
      actuatorInfo: 'Pompa EM4: ${_actuatorStatus['pompa_em4'] == true ? 'ON' : 'OFF'}',
      icon: Icons.science,
      color: AppColors.ph,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCategoryPhScreen()),
      ),
    );
  }

  Widget _buildGasCard() {
    return SensorCard(
      title: 'Gas',
      value: _sensorData!.mq4.toString(),
      unit: 'ppm',
      status: _sensorData!.gasStatus,
      valuePercent: _sensorData!.mq4 / 800,
      actuatorInfo: 'Exhaust Fan: ${_actuatorStatus['exhaust_fan'] == true ? 'ON' : 'OFF'}',
      icon: Icons.air,
      color: AppColors.gas,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCategoryGasScreen()),
      ),
    );
  }






}
