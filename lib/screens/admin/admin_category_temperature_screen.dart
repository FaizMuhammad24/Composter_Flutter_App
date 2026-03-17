import 'package:flutter/material.dart';

class AdminCategoryTemperatureScreen extends StatefulWidget {
  const AdminCategoryTemperatureScreen({Key? key}) : super(key: key);
  @override
  State<AdminCategoryTemperatureScreen> createState() => _AdminCategoryTemperatureScreenState();
}

class _AdminCategoryTemperatureScreenState extends State<AdminCategoryTemperatureScreen> {
  bool _isLoading = true;
  String _selectedPeriod = '24 Jam';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Monitoring Suhu'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: const Color(0xFFFF6B35),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Suhu Terkini', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Icon(Icons.thermostat, color: Colors.white, size: 40),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('58.5°C', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status Heater', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  SizedBox(height: 4),
                                  Text('OFF', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Normal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  children: ['24 Jam', '7 Hari', '30 Hari'].map((period) {
                    final isSelected = _selectedPeriod == period;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _selectedPeriod = period),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected ? const Color(0xFFFF6B35) : Colors.white,
                            foregroundColor: isSelected ? Colors.white : const Color(0xFFFF6B35),
                            side: const BorderSide(color: Color(0xFFFF6B35)),
                          ),
                          child: Text(period),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Grafik Suhu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.show_chart, size: 60, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Grafik Chart (Coming Soon)', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Statistik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildStatRow('Rata-rata', '57.8°C'),
                        const Divider(),
                        _buildStatRow('Tertinggi', '62.1°C', '10:30'),
                        const Divider(),
                        _buildStatRow('Terendah', '52.3°C', '04:15'),
                        const Divider(),
                        _buildStatRow('Heater ON', '45 menit hari ini'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatRow(String label, String value, [String? time]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (time != null) ...[
                const SizedBox(width: 8),
                Text('($time)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
