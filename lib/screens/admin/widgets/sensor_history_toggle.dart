import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget that toggles between a line chart and a data table
/// for sensor history data. All content is within a SINGLE card.
/// Now using TabBar.
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
  int _timeFilter = 0; // 0=Jam, 1=Hari, 2=Minggu

  // We assume here that parent passes all necessary entries.
  // The filtering logic:
  // Jam = 1 jam terakhir (jika 1 menit = 1 data, maka 60 data)
  // Hari = 24 jam terakhir (1440 data)
  // Minggu = 7 hari terakhir (10080 data)
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

  List<FlSpot> get _filteredSpots {
    final limit = _displayLimit.clamp(0, widget.spots.length);
    // Take the most recent spots. Usually spots are added from older to newer (left to right)
    // So to take the 'limit' newest spots, we take them from the end of the list.
    if (widget.spots.length <= limit) return widget.spots;
    final recentSpots = widget.spots.sublist(widget.spots.length - limit);
    // Re-index X axis so it always starts nicely on the graph if we want, or keep original X.
    return recentSpots;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Card(
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

              // TabBar inside a container
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.show_chart, size: 18), SizedBox(width: 8), Text('Grafik')],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.table_chart, size: 18), SizedBox(width: 8), Text('Tabel')],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Time filter
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
              const SizedBox(height: 16),

              // Content: Grafik or Tabel -> TabBarView
              SizedBox(
                height: 380, // Fixed height for the content area to prevent layout jumping
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(), // swipe up/down can be annoying if chart overlaps, but let's allow it or disable
                  children: [
                    _buildChart(),
                    _buildTableContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    final curSpots = _filteredSpots;
    return Column(
      key: const ValueKey('chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${curSpots.length} Data Terakhir Terpantau', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Poppins')),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: curSpots.isEmpty
              ? const Center(child: Text('Belum ada data', style: TextStyle(fontFamily: 'Poppins')))
              : LineChart(
                  LineChartData(
                    minY: widget.minY ?? 0,
                    // Auto scale max Y if possible, or use predefined
                    maxY: widget.maxY,
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: widget.maxY != null ? widget.maxY! / 5 : null),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Could add time format here
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
                        spots: curSpots,
                        isCurved: true,
                        color: widget.color,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [widget.color.withOpacity(0.4), widget.color.withOpacity(0.0)],
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
        Text('${entries.length} data terakhir', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Poppins')),
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
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('Belum ada data', style: TextStyle(fontFamily: 'Poppins')))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final value = entry['value'] as double? ?? 0;
                    final time = entry['time']?.toString() ?? '-';
                    final isNormal = _isInRange(value);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(time, style: TextStyle(fontSize: 11, fontFamily: 'Poppins', color: Colors.grey[700]))),
                        Expanded(flex: 2, child: Text('${value.toStringAsFixed(1)}${widget.unit}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                        Expanded(flex: 2, child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isNormal ? Colors.green : Colors.red).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isNormal ? 'Normal' : 'Abnormal',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNormal ? Colors.green[700] : Colors.red[700], fontFamily: 'Poppins'),
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
