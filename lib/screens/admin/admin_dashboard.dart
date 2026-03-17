import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_elevation.dart';
import '../../utils/screen_utils.dart';
import '../../utils/mock_data.dart';
import '../../models/sensor_data_model.dart';
import '../../models/alert_model.dart';
import '../../widgets/sensor_card.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/loading_shimmer.dart';
import 'admin_category_temperature_screen.dart';
import 'admin_category_humidity_screen.dart';
import 'admin_category_ph_screen.dart';
import 'admin_category_gas_screen.dart';
import 'admin_history_log_screen.dart';
import 'admin_notifications_screen.dart';
import '../authentication/login_screen.dart';

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
  List<AlertModel> _recentAlerts = [];
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
    final alertsJson = MockData.getAlerts(3);

    setState(() {
      _sensorData = SensorDataModel.fromJson(sensorDataJson);
      _actuatorStatus = MockData.getActuatorStatus();
      _recentAlerts = alertsJson.map((json) => AlertModel.fromJson(json)).toList();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  // AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Admin Dashboard'),
      backgroundColor: AppColors.admin,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminHistoryLogScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _showLogoutDialog(),
        ),
      ],
    );
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

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.admin,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Monitoring Sensor Real-time'),
            const SizedBox(height: AppSpacing.md),
            _buildSensorGrid(),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Alert Terbaru'),
            const SizedBox(height: AppSpacing.md),
            _buildRecentAlerts(),
          ],
        ),
      ),
    );
  }

  // Section title
  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.h3);
  }

  // Quick stats row
  Widget _buildQuickStats() {
    final stats = MockData.getDashboardStats();

    return FadeTransition(
      opacity: _animationController,
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              label: 'Total Alert',
              value: stats['active_alerts'].toString(),
              icon: Icons.warning_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatsCard(
              label: 'Alat Aktif',
              value: '${_countActiveActuators()}/5',
              icon: Icons.power,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatsCard(
              label: 'Uptime',
              value: '${stats['system_uptime']}%',
              icon: Icons.access_time,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Sensor grid dengan SensorCard widget
  Widget _buildSensorGrid() {
    if (_sensorData == null) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ScreenUtils.getSensorGridCount(context),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.0,
      children: [
        SensorCard(
          title: 'Suhu',
          value: _sensorData!.temperature.toStringAsFixed(1),
          unit: '°C',
          status: _sensorData!.temperatureStatus,
          actuatorInfo: 'Heater: ${_actuatorStatus['heater'] == true ? 'ON' : 'OFF'}',
          icon: Icons.thermostat,
          color: AppColors.temperature,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoryTemperatureScreen()),
          ),
        ),
        SensorCard(
          title: 'Kelembaban',
          value: _sensorData!.humidity.toStringAsFixed(1),
          unit: '%',
          status: _sensorData!.humidityStatus,
          actuatorInfo: 'Pompa Air: ${_actuatorStatus['pompa_air'] == true ? 'ON' : 'OFF'}',
          icon: Icons.water_drop,
          color: AppColors.humidity,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoryHumidityScreen()),
          ),
        ),
        SensorCard(
          title: 'pH',
          value: _sensorData!.ph.toStringAsFixed(1),
          unit: '',
          status: _sensorData!.phStatus,
          actuatorInfo: 'Pompa FLM: ${_actuatorStatus['pompa_flm'] == true ? 'ON' : 'OFF'}',
          icon: Icons.science,
          color: AppColors.ph,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoryPhScreen()),
          ),
        ),
        SensorCard(
          title: 'Gas',
          value: _sensorData!.mq4.toString(),
          unit: 'ppm',
          status: _sensorData!.gasStatus,
          actuatorInfo: 'Exhaust Fan: ${_actuatorStatus['exhaust_fan'] == true ? 'ON' : 'OFF'}',
          icon: Icons.air,
          color: AppColors.gas,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoryGasScreen()),
          ),
        ),
      ],
    );
  }

  // Recent alerts dengan AlertCard widget
  Widget _buildRecentAlerts() {
    if (_recentAlerts.isEmpty) {
      return Card(
        elevation: AppElevation.md,
        shape: AppRadius.shapeMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
              const SizedBox(height: AppSpacing.sm),
              Text('Tidak ada alert', style: AppTextStyles.bodyLarge),
              Text('Semua sensor dalam kondisi normal', style: AppTextStyles.caption),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentAlerts.map((alert) {
        return AlertCard(
          alert: alert,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
          ),
        );
      }).toList(),
    );
  }

  // Show logout dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: AppRadius.shapeMd,
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
