import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/helpers/csv_export_helper.dart';

class AdminCompostStatusScreen extends StatefulWidget {
  const AdminCompostStatusScreen({Key? key}) : super(key: key);
  @override
  State<AdminCompostStatusScreen> createState() => _AdminCompostStatusScreenState();
}

class _AdminCompostStatusScreenState extends State<AdminCompostStatusScreen> {
  // Live sensor data
  double _temperature = 0;
  double _humidity = 0;
  double _ph = 0;
  bool _isOffline = false;
  DateTime? _lastUpdate;
  Timer? _offlineTimer;

  // Batch info
  DateTime? _batchStartDate;
  bool _isBatchActive = false;

  // Subscriptions
  StreamSubscription? _liveSubscription;
  StreamSubscription? _batchSubscription;

  // Recap data + filter
  List<Map<String, dynamic>> _recapData = [];
  int _selectedFilter = 0; // 0=Jam, 1=Hari, 2=Minggu
  final List<String> _filterLabels = ['Per Jam', 'Per Hari', 'Per Minggu'];

  @override
  void initState() {
    super.initState();
    _listenToLiveData();
    _listenToBatchData();
    _loadRecapData();
    _startOfflineTimer();
  }

  void _startOfflineTimer() {
    _offlineTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastUpdate == null) return;
      if (DateTime.now().difference(_lastUpdate!).inSeconds > 20 && !_isOffline) {
        if (mounted) setState(() => _isOffline = true);
      }
    });
  }

  void _listenToLiveData() {
    _liveSubscription = FirebaseDatabase.instance.ref('komposter').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        bool stale = true;
        if (data.containsKey('unix_time')) {
          final int espUnix = (data['unix_time'] as num).toInt();
          final int phoneUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          stale = (phoneUnix - espUnix).abs() > 60;
        }
        setState(() {
          _isOffline = stale;
          if (!stale) {
            _lastUpdate = DateTime.now();
            _temperature = (data['temperature'] as num?)?.toDouble() ?? 0;
            _humidity = (data['soil'] as num?)?.toDouble() ?? 0;
            _ph = (data['ph'] as num?)?.toDouble() ?? 0;
          }
        });
      }
    });
  }

  void _listenToBatchData() {
    _batchSubscription = FirebaseDatabase.instance.ref('komposter/batch_start').onValue.listen((event) {
      if (mounted) {
        if (event.snapshot.value != null) {
          final int timestamp = (event.snapshot.value as num).toInt();
          setState(() {
            _batchStartDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            _isBatchActive = true;
          });
        } else {
          setState(() { _batchStartDate = null; _isBatchActive = false; });
        }
      }
    });
  }

  Future<void> _loadRecapData() async {
    try {
      // Fetch enough logs for the selected time range
      int limit;
      switch (_selectedFilter) {
        case 0: limit = 1440;  break; // Per Jam: last 24h data
        case 1: limit = 10080; break; // Per Hari: last 7 days
        case 2: limit = 10080; break; // Per Minggu: last ~4 weeks
        default: limit = 1440;
      }

      final snapshot = await FirebaseDatabase.instance
          .ref('komposter_logs').orderByKey().limitToLast(limit).get();

      if (snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        List<Map<String, dynamic>> recap = [];

        // Always group and average
        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var entry in data.entries) {
          final log = Map<String, dynamic>.from(entry.value as Map);
          String groupKey;
          
          if (_selectedFilter == 0) {
            // Per Jam: group by HH:00
            final timeStr = log['time']?.toString() ?? '00:00:00';
            groupKey = timeStr.length >= 2 ? '${timeStr.substring(0, 2)}:00' : timeStr;
          } else if (_selectedFilter == 1) {
            // Per Hari: group by date (YYYY-MM-DD from key)
            groupKey = entry.key.length >= 10 ? entry.key.substring(0, 10) : entry.key;
          } else {
            // Per Minggu: group by week number
            try {
              final datePart = entry.key.substring(0, 10);
              final parts = datePart.split(RegExp(r'[_\-]'));
              if (parts.length >= 3) {
                final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                final weekNum = ((dt.difference(DateTime(dt.year, 1, 1)).inDays) / 7).ceil();
                groupKey = 'Minggu $weekNum (${parts[2]}/${parts[1]})';
              } else {
                groupKey = entry.key.substring(0, 10);
              }
            } catch (_) {
              groupKey = entry.key.substring(0, 10);
            }
          }
          grouped.putIfAbsent(groupKey, () => []).add(log);
        }

        final sortedKeys = grouped.keys.toList()..sort();
        int maxItems = _selectedFilter == 0 ? 24 : (_selectedFilter == 1 ? 7 : 4);
        final recentKeys = sortedKeys.length > maxItems
            ? sortedKeys.sublist(sortedKeys.length - maxItems)
            : sortedKeys;

        for (var key in recentKeys.reversed) {
          final logs = grouped[key]!;
          double avgTemp = 0, avgPh = 0, avgHum = 0;
          for (var log in logs) {
            avgTemp += (log['temperature'] as num?)?.toDouble() ?? 0;
            avgPh += (log['ph'] as num?)?.toDouble() ?? 0;
            avgHum += (log['soil'] as num?)?.toDouble() ?? 0;
          }
          recap.add({
            'time': key,
            'temp': avgTemp / logs.length,
            'ph': avgPh / logs.length,
            'hum': avgHum / logs.length,
            'samples': logs.length,
          });
        }

        setState(() => _recapData = recap);
      }
    } catch (e) {
      debugPrint('Error loading recap: $e');
    }
  }

  Future<void> _downloadRecap() async {
    await CsvExportHelper.exportKomposterLogs(context);
  }

  // === Maturity Calculations ===
  int get _daysSinceStart {
    if (_batchStartDate == null) return 0;
    return DateTime.now().difference(_batchStartDate!).inDays;
  }

  double get _temperatureScore {
    if (_temperature >= 25 && _temperature <= 35) return 100;
    if (_temperature > 35 && _temperature <= 50) return 50;
    if (_temperature < 25) return 70;
    return 20;
  }

  double get _phScore {
    if (_ph >= 6.8 && _ph <= 7.5) return 100;
    if (_ph >= 6.0 && _ph < 6.8) return 60;
    if (_ph > 7.5 && _ph <= 8.5) return 70;
    return 20;
  }

  double get _humidityScore {
    if (_humidity >= 40 && _humidity <= 50) return 100;
    if (_humidity > 50 && _humidity <= 60) return 60;
    if (_humidity >= 30 && _humidity < 40) return 70;
    return 20;
  }

  double get _durationScore {
    if (_daysSinceStart >= 21) return 100;
    if (_daysSinceStart >= 14) return 60;
    if (_daysSinceStart >= 7) return 30;
    return 10;
  }

  double get _totalScore => (_temperatureScore + _phScore + _humidityScore + _durationScore) / 4;

  String get _maturityLabel {
    final score = _totalScore;
    if (score >= 85) return 'Matang';
    if (score >= 50) return 'Proses Pengomposan';
    return 'Belum Matang';
  }

  Color get _maturityColor {
    final score = _totalScore;
    if (score >= 85) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Future<void> _startNewBatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mulai Batch Baru?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Ini akan memulai timer pengomposan baru. Batch lama akan dicatat ke riwayat.', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminPrimary),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await FirebaseDatabase.instance.ref('komposter/batch_start').set(now);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch komposting baru dimulai!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _harvestBatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Panen?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('Kompos telah $_daysSinceStart hari. Tandai batch ini sebagai selesai?', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Panen'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final logRef = FirebaseDatabase.instance.ref('kompos_harvest_log').push();
      await logRef.set({
        'batch_start': _batchStartDate?.millisecondsSinceEpoch,
        'harvest_time': DateTime.now().millisecondsSinceEpoch,
        'duration_days': _daysSinceStart,
        'final_score': _totalScore.toInt(),
        'final_temp': _temperature,
        'final_ph': _ph,
        'final_humidity': _humidity,
      });
      await FirebaseDatabase.instance.ref('komposter/batch_start').remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panen berhasil dicatat!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    _batchSubscription?.cancel();
    _offlineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async { _loadRecapData(); },
      color: AppColors.adminPrimary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMaturityCard(),
            const SizedBox(height: AppSpacing.lg),

            if (_isBatchActive) ...[
              _buildBatchTimerCard(),
              const SizedBox(height: AppSpacing.lg),
            ],

            _buildSectionTitle('Parameter Kematangan'),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _buildParameterCard('Suhu', '${_temperature.toStringAsFixed(1)}°C', _temperatureScore, Icons.thermostat, '25-35°C', AppColors.temperature)),
                const SizedBox(width: 12),
                Expanded(child: _buildParameterCard('pH', _ph.toStringAsFixed(1), _phScore, Icons.science, '6.8-7.5', AppColors.ph)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildParameterCard('Kelembaban', '${_humidity.toStringAsFixed(1)}%', _humidityScore, Icons.water_drop, '40-50%', AppColors.humidity)),
                const SizedBox(width: 12),
                Expanded(child: _buildParameterCard('Durasi', '$_daysSinceStart hari', _durationScore, Icons.calendar_today, '≥21 hari', Colors.teal)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startNewBatch,
                    icon: const Icon(Icons.restart_alt, size: 20),
                    label: const Text('Mulai Batch Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBatchActive && _totalScore >= 70 ? _harvestBatch : null,
                    icon: const Icon(Icons.agriculture, size: 20),
                    label: const Text('Tandai Panen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recap Section with filter + download
            _buildRecapHeader(),
            const SizedBox(height: AppSpacing.sm),
            _buildFilterChips(),
            const SizedBox(height: AppSpacing.md),
            _buildRecapTable(),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.adminPrimary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _buildRecapHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.adminPrimary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('Rekap ${_filterLabels[_selectedFilter]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.download_rounded, color: AppColors.adminPrimary),
          tooltip: 'Download CSV',
          onPressed: _downloadRecap,
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: List.generate(3, (index) {
        final isSelected = _selectedFilter == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_filterLabels[index], style: TextStyle(
              fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.adminPrimary,
            )),
            selected: isSelected,
            selectedColor: AppColors.adminPrimary,
            backgroundColor: AppColors.adminPrimary.withOpacity(0.08),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (sel) {
              if (sel) {
                setState(() => _selectedFilter = index);
                _loadRecapData();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildRecapTable() {
    if (_recapData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('Belum ada data rekap', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: AppColors.adminPrimary.withOpacity(0.1),
              child: Row(
                children: [
                  _tableHeader('Waktu', 2),
                  _tableHeader('Suhu', 2),
                  _tableHeader('pH', 1),
                  _tableHeader('Lembab', 2),
                  _tableHeader('N', 1),
                ],
              ),
            ),
            // Rows
            ...(_recapData.length > 50 ? _recapData.sublist(0, 50) : _recapData).map((d) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
              child: Row(
                children: [
                  _tableCell(d['time'] ?? '-', 2),
                  _tableCell('${(d['temp'] as double).toStringAsFixed(1)}°', 2),
                  _tableCell((d['ph'] as double).toStringAsFixed(1), 1),
                  _tableCell('${(d['hum'] as double).toStringAsFixed(0)}%', 2),
                  _tableCell('${d['samples']}', 1),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 12)),
    );
  }

  Widget _tableCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(fontSize: 11, fontFamily: 'Poppins')),
    );
  }

  Widget _buildMaturityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, _maturityColor.withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _maturityColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: _isBatchActive ? _totalScore / 100 : 0, strokeWidth: 8, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(_maturityColor))),
                Text('${_isBatchActive ? _totalScore.toInt() : 0}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Poppins')),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kematangan Kompos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _maturityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_isBatchActive ? _maturityLabel : 'Belum ada batch', style: TextStyle(color: _maturityColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ),
                const SizedBox(height: 6),
                Text(
                  _isOffline ? 'Sensor sedang offline' : (_isBatchActive ? 'Hari ke-$_daysSinceStart dari proses komposting' : 'Tekan "Mulai Batch Baru" untuk memulai'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTimerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.adminPrimary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.timer, color: AppColors.adminPrimary, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Batch Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                Text('Mulai: ${_batchStartDate != null ? DateFormat('dd MMM yyyy, HH:mm').format(_batchStartDate!) : '-'}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Poppins')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.adminPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('Hari $_daysSinceStart', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.adminPrimary, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard(String label, String value, double score, IconData icon, String target, Color color) {
    final scoreColor = score >= 80 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);
    final scoreLabel = score >= 80 ? 'Matang' : (score >= 50 ? 'Proses' : 'Belum');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: scoreColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(scoreLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scoreColor, fontFamily: 'Poppins')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(_isOffline ? '-' : value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: _isBatchActive ? score / 100 : 0, minHeight: 6, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(scoreColor)),
          ),
          const SizedBox(height: 6),
          Text('Target: $target', style: TextStyle(color: Colors.grey[400], fontSize: 10, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
