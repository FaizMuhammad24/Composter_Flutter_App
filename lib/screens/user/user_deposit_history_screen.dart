import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/compost_model.dart';
import '../../services/history/history_service.dart';
import 'package:intl/intl.dart';

class UserDepositHistoryScreen extends StatefulWidget {
  final String userEmail;
  const UserDepositHistoryScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<UserDepositHistoryScreen> createState() => _UserDepositHistoryScreenState();
}

class _UserDepositHistoryScreenState extends State<UserDepositHistoryScreen> {
  DateTime? _selectedDate;
  bool _isLoading = true;
  List<CompostModel> _allHistory = [];
  List<CompostModel> _displayedHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await HistoryService.getUserHistory(widget.userEmail);
      setState(() {
        _allHistory = history;
        _filterByDate();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat riwayat: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
        DateTime itemDate = DateTime.parse(item.createdAt);
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Setor Sampah',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Berdasarkan Tanggal',
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
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppColors.primary, size: 24),
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
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _clearFilter,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Data Transaksi',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_displayedHistory.length} Setoran',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Poppins'),
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
                                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                const Text('Belum ada riwayat setoran.', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 35,
                              columns: const [
                                DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                DataColumn(label: Text('Berat (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                DataColumn(label: Text('Poin', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                DataColumn(label: Text('Bukti', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                              ],
                              rows: _displayedHistory.map((item) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(item.createdAt)), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12))),
                                    DataCell(Text('${item.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                    DataCell(Text('+${item.points}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                                    DataCell(_buildStatusBadge(item.status)),
                                    DataCell(
                                      item.imageUrl.isNotEmpty 
                                      ? IconButton(
                                          icon: const Icon(Icons.image, color: Colors.blue),
                                          onPressed: () => _showImageDialog(item.imageUrl),
                                        )
                                      : const Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                                  ],
                                );
                              }).toList(),
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status.toUpperCase();

    if (status == 'pending') {
      color = Colors.orange;
      text = 'PENDING';
    } else if (status == 'approved') {
      color = Colors.green;
      text = 'DISETUJUI';
    } else if (status == 'rejected') {
      color = Colors.red;
      text = 'DITOLAK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
      ),
    );
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(url, fit: BoxFit.cover),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins'))),
          ],
        ),
      ),
    );
  }
}
