import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import 'admin_notifications_screen.dart';
import '../../utils/helpers/screen_utils.dart';
import '../../models/sensor_data_model.dart';
import '../../widgets/cards/sensor_card.dart';
import '../../widgets/common/loading_shimmer.dart';
import 'admin_category_temperature_screen.dart';
import 'admin_category_humidity_screen.dart';
import 'admin_category_ph_screen.dart';
import 'admin_category_gas_screen.dart';
import 'admin_history_log_screen.dart';
import '../../services/notifications/notification_service.dart';
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  StreamSubscription<DatabaseEvent>? _rtdbSubscription;
  SensorDataModel? _sensorData;
  Map<String, dynamic> _actuatorStatus = {};
  late AnimationController _animationController;

  // Offline Detection
  DateTime? _lastUpdate;
  Timer? _offlineCheckTimer;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _listenToFirebase();
    _startOfflineTimer();
  }

  bool _isDataStale(Map<dynamic, dynamic> data) {
    // 1. Cek via Unix Timestamp (Paling robust)
    if (data.containsKey('unix_time')) {
      final int espUnix = (data['unix_time'] as num).toInt();
      final int phoneUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final diff = (phoneUnix - espUnix).abs();
      return diff > 60; // 1 Minute tolerance
    }

    // 2. Fallback ke String "time" (HH:mm:ss)
    final String? timeStr = data['time']?.toString();
    if (timeStr == null || timeStr.isEmpty) return true;
    try {
      final parts = timeStr.split(':');
      if (parts.length != 3) return true;
      final now = DateTime.now();
      final dataTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return now.difference(dataTime).inSeconds.abs() > 60;
    } catch (e) {
      return true;
    }
  }

  void _startOfflineTimer() {
    _offlineCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastUpdate == null || _isLoading) return;
      
      final diff = DateTime.now().difference(_lastUpdate!);
      if (diff.inSeconds > 20 && !_isOffline) {
        setState(() {
          _isOffline = true;
          // Reset data stale agar tidak membingungkan
          _sensorData = null;
          _actuatorStatus = {};
        });
      }
    });
  }

  @override
  void dispose() {
    _rtdbSubscription?.cancel();
    _offlineCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Listen data dari Firebase
  void _listenToFirebase() {
    _rtdbSubscription = FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final bool stale = _isDataStale(data);

        if (mounted) {
          setState(() {
            if (stale) {
              _isOffline = true;
            } else {
              _lastUpdate = DateTime.now();
              _isOffline = false;
            }
            
            _sensorData = SensorDataModel.fromJson(data);
            
            final actuators = data['actuators'] as Map? ?? {};
            _actuatorStatus = {
              'Exhaust Fan': actuators['fan'] == true,
              'Heater': actuators['heater'] == true,
              'Motor Aduk': actuators['motor'] == true,
              'Pompa EM4': actuators['em4_pump'] == true,
              'Pompa Air': actuators['water_pump'] == true,
            };
            
            if (_isLoading) {
              _isLoading = false;
              _animationController.forward();
            }
          });
        }
      }
    });
  }

  Future<void> _refreshData() async {
    // Tarik UI untuk refresh (secara teknis data sudah stream realtime)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Count active actuators
  int _countActiveActuators() {
    if (_isOffline) return 0;
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
        onRefresh: _refreshData,
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
              const SizedBox(height: 120), // Bottom padding for nav
            ],
          ),
        ),
      ),
    );
  }



  // Hero Card like User Dashboard
  Widget _buildHeroCard() {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final cardHeight = MediaQuery.of(context).size.height * 0.28; // Dynamic height

    return Container(
      height: cardHeight < 240 ? 240 : cardHeight, // Minimum height fallback
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
                if (_isOffline)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[700],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('SISTEM OFFLINE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationsScreen())),
                        child: ValueListenableBuilder<List<LocalAlert>>(
                          valueListenable: NotificationService.alertsNotifier,
                          builder: (context, alertsList, _) {
                            final unreadCount = _isOffline ? 0 : alertsList.where((a) => !a.isRead).length;
                            return _buildHeroStatCardContent(Icons.warning_amber_rounded, '$unreadCount', 'Total Alert');
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHistoryLogScreen())),
                        child: _buildHeroStatCardContent(Icons.settings_input_component, '${_countActiveActuators()}/5', 'Alat Aktif'),
                      ),
                    ),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                                 const SizedBox(width: 4),
                                 Text(timeStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                               ],
                             ),
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

  Widget _buildHeroStatCardContent(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: Colors.white),
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
    );
  }

  // Symmetrical Sensor Grid (2x2 layout)
  Widget _buildSensorGrid() {
    if (_sensorData == null) return const SizedBox();

    double screenWidth = MediaQuery.of(context).size.width;
    double spacing = screenWidth * 0.04; // 4% of screen width

    return Opacity(
      opacity: _isOffline ? 0.6 : 1.0,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSuhuCard()),
              SizedBox(width: spacing),
              Expanded(child: _buildKelembabanCard()),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(child: _buildPhCard()),
              SizedBox(width: spacing),
              Expanded(child: _buildGasCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalHistory() {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = screenWidth * 0.44; // Proportional width

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('komposter').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator(color: AppColors.adminPrimary)),
          );
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final actuators = Map<String, dynamic>.from(data['actuators'] ?? {});
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 10),
          child: Row(
            children: [
              _buildHistoryItem("Heater", actuators['heater'] == true ? "Aktif" : "Mati", "Suhu: ${data['temperature'] ?? '--'}°C", Colors.orange, itemWidth),
              SizedBox(width: screenWidth * 0.03),
              _buildHistoryItem("Exhaust Fan", actuators['fan'] == true ? "Aktif" : "Mati", "Gas: ${data['gas'] ?? '--'}ppm", Colors.blue, itemWidth),
              SizedBox(width: screenWidth * 0.03),
              _buildHistoryItem("Pompa Air", actuators['water_pump'] == true ? "Aktif" : "Mati", "Lembap: ${data['soil'] ?? '--'}%", Colors.cyan, itemWidth),
              SizedBox(width: screenWidth * 0.03),
              _buildHistoryItem("Pompa EM4", actuators['em4_pump'] == true ? "Aktif" : "Mati", "pH: ${data['ph'] ?? '--'}", Colors.purple, itemWidth),
              SizedBox(width: screenWidth * 0.03),
              _buildHistoryItem("Motor Aduk", actuators['motor'] == true ? "Aktif" : "Mati", actuators['motor'] == true ? "Aktif" : "Selesai", Colors.teal, itemWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(String title, String status, String detail, Color color, double width) {
    bool isActive = status == "Aktif";
    return Container(
      width: width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
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
      value: _isOffline ? '--' : _sensorData!.temperature.toStringAsFixed(1),
      unit: '°C',
      status: _isOffline ? 'Terputus' : _sensorData!.temperatureStatus,
      valuePercent: _isOffline ? 0 : (_sensorData!.temperature - 30) / (80 - 30),
      actuatorInfo: _isOffline ? 'Offline' : 'Heater: ${_actuatorStatus['Heater'] == true ? 'ON' : 'OFF'}',
      icon: Icons.thermostat,
      color: AppColors.temperature,
      isActive: !_isOffline,
      onTap: _isOffline ? null : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCategoryTemperatureScreen()),
      ),
    );
  }

  Widget _buildKelembabanCard() {
    return SensorCard(
      title: 'Kelembaban',
      value: _isOffline ? '--' : (_sensorData!.isSoilHealthy ? _sensorData!.humidity.toStringAsFixed(1) : 'Gagal'),
      unit: _sensorData!.isSoilHealthy ? '%' : '',
      status: _isOffline ? 'Terputus' : _sensorData!.humidityStatus,
      valuePercent: _isOffline ? 0 : _sensorData!.humidity / 100,
      actuatorInfo: _isOffline ? 'Offline' : 'Pompa Air: ${_actuatorStatus['Pompa Air'] == true ? 'ON' : 'OFF'}',
      icon: Icons.water_drop,
      color: AppColors.humidity,
      isActive: !_isOffline,
      onTap: _isOffline ? null : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCategoryHumidityScreen()),
      ),
    );
  }

  Widget _buildPhCard() {
    return SensorCard(
      title: 'pH',
      value: _isOffline ? '--' : (_sensorData!.isPhHealthy ? _sensorData!.ph.toStringAsFixed(1) : 'Gagal'),
      unit: '',
      status: _isOffline ? 'Terputus' : _sensorData!.phStatus,
      valuePercent: _isOffline ? 0 : _sensorData!.ph / 14,
      actuatorInfo: _isOffline ? 'Offline' : 'Pompa EM4: ${_actuatorStatus['Pompa EM4'] == true ? 'ON' : 'OFF'}',
      icon: Icons.science,
      color: AppColors.ph,
      isActive: !_isOffline,
      onTap: _isOffline ? null : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCategoryPhScreen()),
      ),
    );
  }

  Widget _buildGasCard() {
    return SensorCard(
      title: 'Gas',
      value: _isOffline ? '--' : _sensorData!.mq4.toString(),
      unit: 'ppm',
      status: _isOffline ? 'Terputus' : _sensorData!.gasStatus,
      valuePercent: _isOffline ? 0 : _sensorData!.mq4 / 800,
      actuatorInfo: _isOffline ? 'Offline' : 'Exhaust Fan: ${_actuatorStatus['Exhaust Fan'] == true ? 'ON' : 'OFF'}',
      icon: Icons.air,
      color: AppColors.gas,
      isActive: !_isOffline,
      onTap: _isOffline ? null : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCategoryGasScreen()),
      ),
    );
  }






}
