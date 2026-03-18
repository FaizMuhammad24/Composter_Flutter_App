import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/mock_sensor_history.dart';

class AdminCategoryTemperatureScreen extends StatefulWidget {
  const AdminCategoryTemperatureScreen({Key? key}) : super(key: key);
  @override
  State<AdminCategoryTemperatureScreen> createState() => _AdminCategoryTemperatureScreenState();
}

class _AdminCategoryTemperatureScreenState extends State<AdminCategoryTemperatureScreen> {
  bool _isLoading = true;
  String _selectedPeriod = '24 Jam';
  late List<SensorDataPoint> _historyData;
  double _currentValue = 58.5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    _historyData = MockSensorHistory.getTemperatureHistory(_selectedPeriod);
    _currentValue = _historyData.last.value;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Monitoring Suhu', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFFF6B35),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Current Value
                    Card(
                      elevation: 4,
                      color: const Color(0xFFFF6B35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Suhu Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Poppins')),
                                Icon(Icons.thermostat, color: Colors.white, size: 40),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('${_currentValue.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Heater', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                                      const SizedBox(height: 4),
                                      Text(_currentValue < 60 ? 'AKTIF (ON)' : 'MATI (OFF)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    _currentValue <= 60 ? 'Normal' : 'Tinggi',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('Historis Perubahan Suhu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    const SizedBox(height: 16),

                    // Period Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['24 Jam', '7 Hari', '30 Hari'].map((period) {
                          final isSelected = _selectedPeriod == period;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: FilterChip(
                              label: Text(period),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedPeriod = period);
                                _loadData();
                              },
                              selectedColor: const Color(0xFFFF6B35).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? const Color(0xFFFF6B35) : Colors.black54,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                              checkmarkColor: const Color(0xFFFF6B35),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Chart Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Grafik Suhu', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  minY: 40, maxY: 80,
                                  gridData: FlGridData(show: true, drawVerticalLine: false),
                                  titlesData: FlTitlesData(
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: _selectedPeriod == '24 Jam' ? 4 : 24,
                                        getTitlesWidget: (value, meta) {
                                          if (value % (_selectedPeriod == '24 Jam' ? 4 : 24) == 0) {
                                            return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${value.toInt()}:00', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Poppins')));
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  extraLinesData: ExtraLinesData(
                                    horizontalLines: [
                                      HorizontalLine(y: 60, color: Colors.red.withOpacity(0.5), strokeWidth: 2, dashArray: [5, 5], label: HorizontalLineLabel(show: true, labelResolver: (line) => 'Threshold', style: const TextStyle(color: Colors.red, fontSize: 10))),
                                    ],
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _historyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                                      isCurved: true,
                                      color: const Color(0xFFFF6B35),
                                      barWidth: 3,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [const Color(0xFFFF6B35).withOpacity(0.3), const Color(0xFFFF6B35).withOpacity(0.0)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
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

                    const SizedBox(height: 20),

                    // Stats Info
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Statistik', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            const SizedBox(height: 16),
                            _buildStatRow('Rata-rata', '${_calculateAvg().toStringAsFixed(1)}°C'),
                            const Divider(),
                            _buildStatRow('Tertinggi', '${_calculateMax().toStringAsFixed(1)}°C'),
                            const Divider(),
                            _buildStatRow('Heater Runtime', '2.5 Jam hari ini'),
                            const Divider(),
                            _buildStatRow('Alert Terdeteksi', '0 Kejadian'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  double _calculateAvg() => _historyData.isNotEmpty ? _historyData.map((e) => e.value).reduce((a, b) => a + b) / _historyData.length : 0;
  double _calculateMax() => _historyData.isNotEmpty ? _historyData.map((e) => e.value).reduce((a, b) => a > b ? a : b) : 0;

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontFamily: 'Poppins')),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
