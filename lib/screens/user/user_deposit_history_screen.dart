import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'package:intl/intl.dart';

class UserDepositHistoryScreen extends StatefulWidget {
  const UserDepositHistoryScreen({Key? key}) : super(key: key);

  @override
  State<UserDepositHistoryScreen> createState() => _UserDepositHistoryScreenState();
}

class _UserDepositHistoryScreenState extends State<UserDepositHistoryScreen> {
  DateTime? _selectedDate;

  // Data Dummy untuk disimulasikan sebagai Riwayat
  final List<Map<String, dynamic>> _allHistory = [
    {'date': DateTime(2026, 3, 18), 'type': 'Organik Basah', 'weight': 5.0, 'points': 50},
    {'date': DateTime(2026, 3, 18), 'type': 'Campuran', 'weight': 2.0, 'points': 12},
    {'date': DateTime(2026, 3, 17), 'type': 'Organik Kering', 'weight': 3.5, 'points': 28},
    {'date': DateTime(2026, 3, 15), 'type': 'Organik Basah', 'weight': 10.0, 'points': 100},
    {'date': DateTime(2026, 3, 10), 'type': 'Campuran', 'weight': 4.0, 'points': 24},
    {'date': DateTime(2026, 3, 1), 'type': 'Organik Kering', 'weight': 5.0, 'points': 40},
  ];

  List<Map<String, dynamic>> _displayedHistory = [];

  @override
  void initState() {
    super.initState();
    _displayedHistory = List.from(_allHistory);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2026, 3, 18),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filterByDate();
      });
    }
  }

  void _filterByDate() {
    if (_selectedDate == null) {
      _displayedHistory = List.from(_allHistory);
    } else {
      _displayedHistory = _allHistory.where((item) {
        DateTime itemDate = item['date'];
        return itemDate.year == _selectedDate!.year &&
               itemDate.month == _selectedDate!.month &&
               itemDate.day == _selectedDate!.day;
      }).toList();
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedDate = null;
      _filterByDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar abu-abu super soft
      appBar: AppBar(
        title: const Text(
          'Tabel Riwayat Setor',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Ikon tombol back putih
      ),
      body: Column(
        children: [
          // BAGIAN PENCARIAN & FILTER
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari Berdasarkan Tanggal',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate == null
                                    ? 'Semua Tanggal'
                                    : DateFormat('dd MMM yyyy').format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null ? Colors.grey[500] : Colors.black87,
                                  fontFamily: 'Poppins',
                                  fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _clearFilter,
                          tooltip: 'Hapus Filter',
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // BAGIAN TABEL DATA
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Data Riwayat',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_displayedHistory.length} Transaksi',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Poppins'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_displayedHistory.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada riwayat pada tanggal ini.',
                                style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey[50]),
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 60,
                              horizontalMargin: 20,
                              columnSpacing: 24,
                              columns: const [
                                DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                DataColumn(label: Text('Jenis Sampah', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                DataColumn(label: Text('Berat\n(kg)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                DataColumn(label: Text('Poin', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                              ],
                              rows: _displayedHistory.map((item) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(DateFormat('dd/MM/yyyy').format(item['date']), style: const TextStyle(fontFamily: 'Poppins', color: Colors.black87))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item['type'] == 'Organik Basah' ? Colors.green.withValues(alpha: 0.1) 
                                               : item['type'] == 'Organik Kering' ? Colors.orange.withValues(alpha: 0.1) 
                                               : Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item['type'],
                                          style: TextStyle(
                                            fontFamily: 'Poppins', 
                                            fontSize: 12,
                                            color: item['type'] == 'Organik Basah' ? Colors.green[700] 
                                                 : item['type'] == 'Organik Kering' ? Colors.orange[800] 
                                                 : Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(item['weight'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                    DataCell(
                                      Text(
                                        '+${item['points']}', 
                                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
