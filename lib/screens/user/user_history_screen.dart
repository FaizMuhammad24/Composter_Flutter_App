import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/history/history_service.dart';
import '../../models/compost_model.dart';
import 'package:intl/intl.dart';

class UserHistoryScreen extends StatefulWidget {
  final UserModel user;
  const UserHistoryScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  bool _isLoading = true;
  List<CompostModel> _recentTransactions = [];
  double _totalWeight = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final history = await HistoryService.getUserHistory(widget.user.email);
      double weightSum = 0;
      for (var item in history) {
        weightSum += item.weight;
      }
      setState(() {
        _recentTransactions = history.take(10).toList();
        _totalWeight = weightSum;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil & Riwayat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Poin Anda',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.user.points ?? 0} Pts',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatCard(
                        value: '${_totalWeight.toStringAsFixed(1)} kg',
                        label: 'Total Setor',
                        color: const Color(0xFF81D4FA),
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        value: '0x', // Placeholder for now
                        label: 'Reward Ditukar',
                        color: const Color(0xFFFFB74D),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text('Riwayat Transaksi Terakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    ),
                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : _recentTransactions.isEmpty
                          ? const Center(child: Text('Belum ada transaksi.', style: TextStyle(fontFamily: 'Poppins')))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: _recentTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = _recentTransactions[index];
                                return _buildTransactionItem(
                                  icon: Icons.recycling,
                                  iconColor: AppColors.primary,
                                  title: 'Setor Sampah',
                                  subtitle: DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tx.createdAt)),
                                  amount: '+${tx.points} Pts',
                                  amountColor: Colors.orange,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String value, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Poppins')),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: amountColor, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
