import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import '../notifications/admin_system_notifications_screen.dart';
import '../../../utils/helpers/screen_utils.dart';
import '../../../utils/helpers/csv_export_helper.dart';
import '../../../models/sensor_data_model.dart';
import '../../../widgets/cards/sensor_card.dart';
import '../../../widgets/common/loading_shimmer.dart';
import '../system/admin_category_temperature_screen.dart';
import '../system/admin_category_humidity_screen.dart';
import '../system/admin_category_ph_screen.dart';
import '../system/admin_category_gas_screen.dart';
import '../../../services/notifications/admin_notification_service.dart';
import '../../../services/notifications/management_notification_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  StreamSubscription<DatabaseEvent>? _rtdbSubscription;
  SensorDataModel? _sensorData;

  late AnimationController _animationController;

  // Recap data
  List<Map<String, dynamic>> _recapData = [];
  int _selectedFilter = 0; // 0=Jam, 1=Hari, 2=Minggu
  final List<String> _filterLabels = ['Per Jam', 'Per Hari', 'Per Minggu'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _listenToFirebase();
    _loadRecapData();
  }

  @override
  void dispose() {
    _rtdbSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Listen data dari Firebase
  void _listenToFirebase() {
    _rtdbSubscription = FirebaseDatabase.instance.ref('komposter').onValue.listen(
      (event) {
        if (!mounted) return;
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            _sensorData = SensorDataModel.fromJson(data);
            if (_isLoading) {
              _isLoading = false;
              _animationController.forward();
            }
          });
        } else {
          // Data null (node kosong/belum ada) — hentikan loading
          setState(() => _isLoading = false);
        }
      },
      onError: (error) {
        // Error koneksi Firebase — hentikan loading agar tidak stuck
        debugPrint('Firebase listener error: $error');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _loadRecapData() async {
    try {
      int limit;
      switch (_selectedFilter) {
        case 0: limit = 1440;  break;
        case 1: limit = 10080; break;
        case 2: limit = 10080; break;
        default: limit = 1440;
      }

      final snapshot = await FirebaseDatabase.instance
          .ref('komposter_logs').orderByKey().limitToLast(limit).get();

      if (snapshot.value != null && mounted) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        List<Map<String, dynamic>> recap = [];
        Map<String, List<Map<String, dynamic>>> grouped = {};

        for (var entry in data.entries) {
          final log = Map<String, dynamic>.from(entry.value as Map);
          String groupKey;
          
          DateTime dt;
          if (log.containsKey('unix_time')) {
            dt = DateTime.fromMillisecondsSinceEpoch((log['unix_time'] as num).toInt() * 1000);
          } else {
            dt = DateTime.now(); // fallback
          }

          // Filter invalid years immediately so they don't corrupt the sorting and maxItems
          if (dt.year < 2024 || dt.year > 2030) {
            continue;
          }

          if (_selectedFilter == 0) {
            // Per Jam: group by yyyy-MM-dd HH:00
            groupKey = DateFormat('yyyy-MM-dd HH:00').format(dt);
          } else if (_selectedFilter == 1) {
            // Per Hari: group by yyyy-MM-dd
            groupKey = DateFormat('yyyy-MM-dd').format(dt);
          } else {
            // Per Minggu
            final weekNum = ((dt.difference(DateTime(dt.year, 1, 1)).inDays) / 7).ceil();
            groupKey = '${dt.year}-W${weekNum.toString().padLeft(2, '0')}';
          }
          
          grouped.putIfAbsent(groupKey, () => []).add(log);
        }

        final sortedKeys = grouped.keys.toList()..sort();
        int maxItems = _selectedFilter == 0 ? 12 : (_selectedFilter == 1 ? 7 : 4);
        final recentKeys = sortedKeys.length > maxItems
            ? sortedKeys.sublist(sortedKeys.length - maxItems)
            : sortedKeys;

        for (var key in recentKeys.reversed) {
          final logs = grouped[key]!;
          double avgTemp = 0, avgPh = 0, avgHum = 0;
          for (var log in logs) {
            double t = (log['temperature'] as num?)?.toDouble() ?? 0;
            double p = (log['ph'] as num?)?.toDouble() ?? 0;
            double h = (log['soil'] as num?)?.toDouble() ?? 0;
            
            // Abaikan nilai error (-127 dari DHT22, atau 100/0 untuk pH error)
            if (t > -50 && t < 100) avgTemp += t;
            if (p > 0 && p < 14) avgPh += p;
            if (h >= 0 && h <= 100) avgHum += h;
          }

          // Parse date info from key
          String dayName = '';
          String dateStr = '';
          String hourStr = '-';
          try {
            if (_selectedFilter == 0) {
              // Per Jam
              final dt = DateFormat('yyyy-MM-dd HH:00').parse(key);
              dateStr = DateFormat('dd MMM, HH:00').format(dt); // Gabung tanggal dan jam
              dayName = DateFormat('EEEE').format(dt);
            } else if (_selectedFilter == 1) {
              // Per Hari
              final dt = DateFormat('yyyy-MM-dd').parse(key);
              dateStr = DateFormat('dd MMM yyyy').format(dt);
              dayName = DateFormat('EEEE').format(dt);
            } else {
              // Per Minggu
              final year = int.tryParse(key.split('-W')[0]) ?? 2026;
              dateStr = '$year';
              dayName = 'Minggu ${key.split('-W')[1]}';
            }
          } catch (_) {
            dateStr = key;
          }

          recap.add({
            'dayName': dayName,
            'dateStr': dateStr,
            'hourStr': hourStr,
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

  Future<void> _refreshData() async {
    _loadRecapData();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminNotificationService.deviceOfflineNotifier,
      builder: (context, isOffline, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _buildFABTips(),
          body: _isLoading ? _buildLoadingState() : _buildContent(isOffline),
        );
      },
    );
  }

  Widget _buildFABTips() {
    return FloatingActionButton(
      onPressed: () => _showTipsDialog(),
      backgroundColor: AppColors.adminPrimary,
      child: const Icon(Icons.lightbulb_outline, color: Colors.white),
    );
  }

  void _showTipsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('📖 Panduan Kompos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ),
                const TabBar(
                  labelColor: AppColors.adminPrimary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.adminPrimary,
                  labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: [
                    Tab(text: 'Tips'),
                    Tab(text: 'Standar SNI'),
                    Tab(text: 'Bahan'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTipsTab(scrollController),
                      _buildSNITab(scrollController),
                      _buildBahanTab(scrollController),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsTab(ScrollController controller) {
    final tips = [
      {'icon': '🥬', 'title': 'Siapkan Bahan', 'desc': 'Campurkan bahan hijau (sampah dapur) dan coklat (daun kering) dengan rasio 3:1'},
      {'icon': '💧', 'title': 'Kelembaban', 'desc': 'Jaga kelembaban 40-60%. Kompos yang baik terasa lembab tapi tidak basah'},
      {'icon': '🌡️', 'title': 'Suhu', 'desc': 'Suhu ideal 40-60°C saat proses aktif. Fase matang turun ke 25-35°C'},
      {'icon': '🔄', 'title': 'Pengadukan', 'desc': 'Aduk kompos 1-2x sehari untuk sirkulasi udara dan percepat dekomposisi'},
      {'icon': '⏰', 'title': 'Durasi', 'desc': 'Proses komposting membutuhkan 21-30 hari hingga matang sempurna'},
      {'icon': '✅', 'title': 'Ciri Matang', 'desc': 'Warna coklat gelap, tidak berbau, suhu ambient, pH netral (6.8-7.5)'},
    ];
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adminPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.adminPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tips[i]['icon']!, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tips[i]['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14)),
                const SizedBox(height: 4),
                Text(tips[i]['desc']!, style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.grey[700], height: 1.4)),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSNITab(ScrollController controller) {
    final params = [
      ['Parameter', 'Standar SNI', 'Unit'],
      ['Suhu', '25 – 35', '°C'],
      ['pH', '6.80 – 7.49', ''],
      ['Kelembaban', '40 – 50', '%'],
      ['C/N Ratio', '10 – 20', ''],
      ['Kadar Air', '≤ 50', '%'],
      ['Warna', 'Coklat kehitaman', ''],
      ['Bau', 'Berbau tanah', ''],
      ['Ukuran partikel', '0.55 – 25', 'mm'],
    ];
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Standar SNI 19-7030-2004 — Spesifikasi Kompos', style: TextStyle(fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.green))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Table(
              border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade100)),
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1)},
              children: params.asMap().entries.map((e) {
                final isHeader = e.key == 0;
                return TableRow(
                  decoration: BoxDecoration(color: isHeader ? AppColors.adminPrimary.withValues(alpha: 0.08) : null),
                  children: e.value.map((cell) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(cell, style: TextStyle(
                      fontSize: 12, fontFamily: 'Poppins',
                      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                      color: isHeader ? AppColors.adminPrimary : Colors.black87,
                    )),
                  )).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBahanTab(ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16),
      children: [
        _buildBahanSection('🟢 Bahan Hijau (Nitrogen)', Colors.green, [
          'Sisa sayuran & buah',
          'Rumput segar',
          'Ampas kopi & teh',
          'Kulit telur (dihancurkan)',
        ]),
        const SizedBox(height: 16),
        _buildBahanSection('🟤 Bahan Coklat (Karbon)', Colors.brown, [
          'Daun kering',
          'Serbuk gergaji',
          'Karton/kertas',
          'Ranting kecil',
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('⚖️', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('Rasio Ideal', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Coklat : Hijau = 3 : 1', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.brown[700])),
              const SizedBox(height: 4),
              Text('3 bagian karbon untuk setiap 1 bagian nitrogen', style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.do_not_disturb, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Hindari', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
              ...['Daging & tulang', 'Produk susu', 'Minyak & lemak', 'Tanaman berpenyakit'].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.close, size: 14, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(item, style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.grey[700])),
                ]),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBahanSection(String title, Color color, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 14, color: color.withValues(alpha: 0.8))),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(Icons.check_circle, size: 16, color: color.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(item, style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.grey[700])),
            ]),
          )),
        ],
      ),
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
  Widget _buildContent(bool isOffline) {
    if (_sensorData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada data sensor',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan perangkat ESP32 menyala\ndan terhubung ke internet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(color: AppColors.adminBg),
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.adminPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(isOffline),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Monitoring Sensor Real-time'),
              const SizedBox(height: AppSpacing.md),
              _buildSensorGrid(isOffline),
              const SizedBox(height: AppSpacing.lg),
              // Rekap Section
              _buildRecapHeader(),
              const SizedBox(height: AppSpacing.sm),
              _buildFilterChips(),
              const SizedBox(height: AppSpacing.md),
              _buildRecapTable(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }


  // === REKAP SECTION ===
  Widget _buildRecapHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.adminPrimary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text('Rekap ${_filterLabels[_selectedFilter]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        ]),
        IconButton(
          icon: const Icon(Icons.download_rounded, color: AppColors.adminPrimary),
          tooltip: 'Download CSV',
          onPressed: () => CsvExportHelper.exportKomposterLogs(context),
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
            backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.08),
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
      width: double.infinity,
      height: 300, // Fixed height for vertical scrolling (minimal 5 rows)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView( // Vertical scroll
          child: SingleChildScrollView( // Horizontal scroll
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 14,
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                headingRowColor: WidgetStateProperty.all(AppColors.adminPrimary.withValues(alpha: 0.08)),
                columns: const [
                  DataColumn(label: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 12))),
                  DataColumn(label: Text('Suhu', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 12))),
                  DataColumn(label: Text('pH', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 12))),
                  DataColumn(label: Text('Lembab', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 12))),
                  DataColumn(label: Text('N', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 12))),
                ],
                rows: _recapData.map((d) => DataRow(cells: [
                  DataCell(Text('${d['dayName'] ?? '-'}, ${d['dateStr'] ?? '-'}', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600))),
                  DataCell(Text('${(d['temp'] as double).toStringAsFixed(1)}°', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'))),
                  DataCell(Text((d['ph'] as double).toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'))),
                  DataCell(Text('${(d['hum'] as double).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'))),
                  DataCell(Text('${d['samples']}', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'))),
                ])).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hero Card
  Widget _buildHeroCard(bool isOffline) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Panel Kendali Admin', style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Poppins')),
                    Text('Monitoring Sistem', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, _) {
                    final now = DateTime.now();
                    final timeStr = DateFormat('HH:mm').format(now);
                    final dateStr = '${DateFormat('EEEE').format(now)}, ${DateFormat('d MMM yyyy').format(now)}';
                    return Column(
                      children: [
                        Text(timeStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                        Text(dateStr, style: const TextStyle(fontSize: 8, color: Colors.white70, fontFamily: 'Poppins')),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row: status badges
          Row(
            children: [
              // Alert badge
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSystemNotificationsScreen())),
                child: StreamBuilder<int>(
                  stream: ManagementNotificationService.getUnreadCountStream(),
                  builder: (context, snapshot) {
                    final managementUnreadCount = snapshot.data ?? 0;
                    return ValueListenableBuilder<List<LocalAlert>>(
                      valueListenable: AdminNotificationService.alertsNotifier,
                      builder: (context, alertsList, _) {
                        final localUnreadCount = isOffline ? 0 : alertsList.where((a) => !a.isRead && a.severity != 'info').length;
                        final totalUnreadCount = managementUnreadCount + localUnreadCount;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: totalUnreadCount > 0 ? Colors.red.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 6),
                              Text('$totalUnreadCount Alert', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Online/Offline badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOffline ? Colors.red[700] : Colors.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isOffline ? Icons.wifi_off : Icons.wifi, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(isOffline ? 'OFFLINE' : 'ONLINE', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Sensor Grid (2x2)
  Widget _buildSensorGrid(bool isOffline) {
    if (_sensorData == null) return const SizedBox();

    double screenWidth = MediaQuery.of(context).size.width;
    double spacing = screenWidth * 0.04;

    return Opacity(
      opacity: isOffline ? 0.6 : 1.0,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSuhuCard(isOffline)),
              SizedBox(width: spacing),
              Expanded(child: _buildKelembabanCard(isOffline)),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(child: _buildPhCard(isOffline)),
              SizedBox(width: spacing),
              Expanded(child: _buildGasCard(isOffline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins')),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSuhuCard(bool isOffline) {
    return SensorCard(
      title: 'Suhu',
      value: _sensorData!.temperature.toStringAsFixed(1),
      unit: '°C',
      status: isOffline ? 'Terputus' : _sensorData!.temperatureStatus,
      valuePercent: (_sensorData!.temperature - 30) / (80 - 30),
      targetNote: 'Target SNI: 25-35°C',
      icon: Icons.thermostat,
      color: AppColors.temperature,
      isActive: !isOffline,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoryTemperatureScreen())),
    );
  }

  Widget _buildKelembabanCard(bool isOffline) {
    return SensorCard(
      title: 'Kelembaban',
      value: _sensorData!.isSoilHealthy ? _sensorData!.humidity.toStringAsFixed(1) : 'Gagal',
      unit: _sensorData!.isSoilHealthy ? '%' : '',
      status: isOffline ? 'Terputus' : _sensorData!.humidityStatus,
      valuePercent: _sensorData!.humidity / 100,
      targetNote: 'Target SNI: 40-50%',
      icon: Icons.water_drop,
      color: AppColors.humidity,
      isActive: !isOffline,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoryHumidityScreen())),
    );
  }

  Widget _buildPhCard(bool isOffline) {
    return SensorCard(
      title: 'pH',
      value: _sensorData!.isPhHealthy ? _sensorData!.ph.toStringAsFixed(1) : 'Gagal',
      unit: '',
      status: isOffline ? 'Terputus' : _sensorData!.phStatus,
      valuePercent: _sensorData!.ph / 14,
      targetNote: 'Target SNI: 6.8-7.5',
      icon: Icons.science,
      color: AppColors.ph,
      isActive: !isOffline,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoryPhScreen())),
    );
  }

  Widget _buildGasCard(bool isOffline) {
    return SensorCard(
      title: 'Gas',
      value: _sensorData!.mq4.toString(),
      unit: 'ppm',
      status: isOffline ? 'Terputus' : _sensorData!.gasStatus,
      valuePercent: _sensorData!.mq4 / 800,
      targetNote: 'Batas Max: 50 ppm',
      icon: Icons.air,
      color: AppColors.gas,
      isActive: !isOffline,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoryGasScreen())),
    );
  }
}
