import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget that toggles between a line chart and a data table
/// for sensor history data. All content is within a SINGLE card.
class SensorHistoryToggle extends StatefulWidget {
  final List<FlSpot> spots;
  final List<Map<String, dynamic>> logEntries;
  final String sensorLabel;
  final String unit;
  final Color color;
  final double? minY;
  final double? maxY;
  final double? thresholdMin;
  final double? thresholdMax;

  const SensorHistoryToggle({
    Key? key,
    required this.spots,
    required this.logEntries,
    required this.sensorLabel,
    required this.unit,
    required this.color,
    this.minY,
    this.maxY,
    this.thresholdMin,
    this.thresholdMax,
  }) : super(key: key);

  @override
  State<SensorHistoryToggle> createState() => _SensorHistoryToggleState();
}

class _SensorHistoryToggleState extends State<SensorHistoryToggle> {
  int _viewIndex = 0; // 0=Grafik, 1=Tabel
  int _timeFilter = 0; // 0=Jam, 1=Hari, 2=Minggu

  int get _displayLimit {
    switch (_timeFilter) {
      case 0: return 60;
      case 1: return 1440;
      case 2: return 10080;
      default: return 60;
    }
  }

  List<Map<String, dynamic>> get _filteredEntries {
    final limit = _displayLimit.clamp(0, widget.logEntries.length);
    return widget.logEntries.take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Historis Perubahan ${widget.sensorLabel}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),

            // Toggle buttons row — compact segmented style
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSegmentBtn(0, Icons.show_chart, 'Grafik'),
                  _buildSegmentBtn(1, Icons.table_chart, 'Tabel'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content: Grafik or Tabel (inside the same card)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _viewIndex == 0 ? _buildChart() : _buildTableContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentBtn(int index, IconData icon, String label) {
    final isSelected = _viewIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _viewIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins',
              color: isSelected ? Colors.white : Colors.grey[600],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Column(
      key: const ValueKey('chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.spots.length} Log Terakhir', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Poppins')),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: widget.spots.isEmpty
              ? const Center(child: Text('Belum ada data'))
              : LineChart(
                  LineChartData(
                    minY: widget.minY ?? 0,
                    maxY: widget.maxY,
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        if (widget.thresholdMax != null)
                          HorizontalLine(y: widget.thresholdMax!, color: Colors.orange.withOpacity(0.5), strokeWidth: 2, dashArray: [5, 5],
                            label: HorizontalLineLabel(show: true, labelResolver: (line) => 'Batas Atas', style: const TextStyle(color: Colors.orange, fontSize: 10))),
                        if (widget.thresholdMin != null)
                          HorizontalLine(y: widget.thresholdMin!, color: Colors.red.withOpacity(0.5), strokeWidth: 2, dashArray: [5, 5],
                            label: HorizontalLineLabel(show: true, padding: const EdgeInsets.only(bottom: 20), labelResolver: (line) => 'Batas Bawah', style: const TextStyle(color: Colors.red, fontSize: 10))),
                      ],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: widget.spots,
                        isCurved: true,
                        color: widget.color,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [widget.color.withOpacity(0.3), widget.color.withOpacity(0.0)],
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
    );
  }

  Widget _buildTableContent() {
    final entries = _filteredEntries;
    return Column(
      key: const ValueKey('table'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time filter — Wrap to prevent overflow
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(3, (i) {
            final labels = ['Per Jam', 'Per Hari', 'Per Minggu'];
            final isSelected = _timeFilter == i;
            return GestureDetector(
              onTap: () => setState(() => _timeFilter = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? widget.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? widget.color : widget.color.withOpacity(0.3)),
                ),
                child: Text(labels[i], style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                  color: isSelected ? Colors.white : widget.color,
                )),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text('${entries.length} data', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Poppins')),
        const SizedBox(height: 8),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(color: widget.color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(flex: 3, child: Text('Waktu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: widget.color))),
            Expanded(flex: 2, child: Text(widget.sensorLabel, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: widget.color))),
            Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: widget.color))),
          ]),
        ),

        // Table Body
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: entries.isEmpty
              ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada data', style: TextStyle(fontFamily: 'Poppins'))))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length.clamp(0, 50),
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final value = entry['value'] as double? ?? 0;
                    final time = entry['time']?.toString() ?? '-';
                    final isNormal = _isInRange(value);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(time, style: TextStyle(fontSize: 11, fontFamily: 'Poppins', color: Colors.grey[700]))),
                        Expanded(flex: 2, child: Text('${value.toStringAsFixed(1)}${widget.unit}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                        Expanded(flex: 2, child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isNormal ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isNormal ? 'Normal' : 'Abnormal',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isNormal ? Colors.green[700] : Colors.red[700], fontFamily: 'Poppins'),
                            ),
                          ),
                        )),
                      ]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _isInRange(double value) {
    if (widget.thresholdMin != null && value < widget.thresholdMin!) return false;
    if (widget.thresholdMax != null && value > widget.thresholdMax!) return false;
    return true;
  }
}
