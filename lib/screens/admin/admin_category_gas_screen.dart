import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/mocks/mock_sensor_history.dart';

class AdminCategoryGasScreen extends StatefulWidget {
  const AdminCategoryGasScreen({Key? key}) : super(key: key);
  @override
  State<AdminCategoryGasScreen> createState() => _AdminCategoryGasScreenState();
}

class _AdminCategoryGasScreenState extends State<AdminCategoryGasScreen> {
  bool _isLoading = true;
  String _selectedPeriod = '24 Jam';
  late List<SensorDataPoint> _historyData;
  double _currentValue = 520.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    _historyData = MockSensorHistory.getGasHistory(_selectedPeriod);
    _currentValue = _historyData.last.value;
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Monitoring Gas (MQ-4)', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data berhasil diekspor ke CSV')),
              );
            },
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFE53935),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning Banner
                    if (_currentValue > 500)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[400]!),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('BAHAYA: KADAR GAS TINGGI', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                  Text('Kadar gas metana melebihi 500 ppm. Segera menjauh atau pastikan sirkulasi udara baik.', style: TextStyle(color: Color(0xFFE53935), fontSize: 12, fontFamily: 'Poppins')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Header Current Value
                    Card(
                      elevation: 4,
                      color: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Kadar Gas Metana', style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Poppins')),
                                Icon(Icons.waves, color: Colors.white, size: 40),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('${_currentValue.toStringAsFixed(0)} ppm', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Exhaust Fan', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                                      const SizedBox(height: 4),
                                      Text(_currentValue > 500 ? 'AKTIF (ON)' : 'MATI (OFF)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
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
                                    _currentValue > 500 ? 'Bahaya' : (_currentValue > 400 ? 'Waspada' : 'Normal'),
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
                    const Text('Analisis Grafik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
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
                              selectedColor: const Color(0xFFE53935).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected ? const Color(0xFFE53935) : Colors.black54,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                              checkmarkColor: const Color(0xFFE53935),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFFE53935) : Colors.transparent)),
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
                            const Text('Tren Konsentrasi Gas', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 150),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: _selectedPeriod == '24 Jam' ? 4 : 24,
                                        getTitlesWidget: (value, meta) {
                                          if (value % (_selectedPeriod == '24 Jam' ? 4 : 24) == 0) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text('${value.toInt()}:00', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Poppins')),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  extraLinesData: ExtraLinesData(
                                    horizontalLines: [
                                      HorizontalLine(y: 500, color: Colors.red.withOpacity(0.5), strokeWidth: 2, dashArray: [5, 5], label: HorizontalLineLabel(show: true, labelResolver: (line) => 'Bahaya', style: const TextStyle(color: Colors.red, fontSize: 10))),
                                      HorizontalLine(y: 350, color: Colors.orange.withOpacity(0.5), strokeWidth: 1, dashArray: [5, 5], label: HorizontalLineLabel(show: true, labelResolver: (line) => 'Waspada', style: const TextStyle(color: Colors.orange, fontSize: 10))),
                                    ],
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _historyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                                      isCurved: true,
                                      color: const Color(0xFFE53935),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [const Color(0xFFE53935).withOpacity(0.3), const Color(0xFFE53935).withOpacity(0.0)],
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
                            const Text('Informasi Lanjutan', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            const SizedBox(height: 16),
                            _buildStatRow('Rata-rata', '${_calculateAvg().toStringAsFixed(1)} ppm'),
                            const Divider(),
                            _buildStatRow('Tertinggi', '${_calculateMax().toStringAsFixed(1)} ppm'),
                            const Divider(),
                            _buildStatRow('Fan Runtime', '1.2 Jam hari ini'),
                            const Divider(),
                            _buildStatRow('Threshold Fan', '500 ppm'),
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

  double _calculateAvg() => _historyData.map((e) => e.value).reduce((a, b) => a + b) / _historyData.length;
  double _calculateMax() => _historyData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

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
