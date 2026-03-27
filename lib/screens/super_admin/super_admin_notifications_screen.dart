import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/notifications/admin_notification_service.dart';

class SuperAdminNotificationsScreen extends StatefulWidget {
  final String adminEmail;
  const SuperAdminNotificationsScreen({Key? key, required this.adminEmail}) : super(key: key);

  @override
  State<SuperAdminNotificationsScreen> createState() => _SuperAdminNotificationsScreenState();
}

class _SuperAdminNotificationsScreenState extends State<SuperAdminNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Streams for activities
  StreamSubscription? _depSub;
  StreamSubscription? _claimSub;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _depList = [];
  List<Map<String, dynamic>> _claimList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initStreams();
  }

  void _initStreams() {
    _depSub = FirebaseFirestore.instance
        .collection('composts')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      _depList = snap.docs.map((d) {
        final data = d.data();
        return {...data, 'activity_type': 'deposit', 'doc_id': d.id};
      }).toList();
      _combineAndSort();
    });

    _claimSub = FirebaseFirestore.instance
        .collection('reward_claims')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      _claimList = snap.docs.map((d) {
        final data = d.data();
        return {...data, 'activity_type': 'claim', 'doc_id': d.id};
      }).toList();
      _combineAndSort();
    });
  }

  void _combineAndSort() {
    final combined = [..._depList, ..._claimList];
    combined.sort((a, b) {
      final valA = a['createdAt'];
      final valB = b['createdAt'];
      DateTime dateA = DateTime.fromMillisecondsSinceEpoch(0);
      DateTime dateB = DateTime.fromMillisecondsSinceEpoch(0);
      
      if (valA is Timestamp) dateA = valA.toDate();
      else if (valA is String) dateA = DateTime.tryParse(valA) ?? dateA;
      
      if (valB is Timestamp) dateB = valB.toDate();
      else if (valB is String) dateB = DateTime.tryParse(valB) ?? dateB;

      return dateB.compareTo(dateA);
    });
    setState(() {
      _activities = combined;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _depSub?.cancel();
    _claimSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.superAdminBg,
      appBar: AppBar(
        title: const Text(
          'Aktivitas & Notifikasi',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.superAdminPrimary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Admin (System)'),
            Tab(text: 'Aktivitas User'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdminTab(),
          _buildUserActivityTab(),
        ],
      ),
    );
  }

  // ============== TAB 1: SYSTEM / ADMIN =================
  Widget _buildAdminTab() {
    return ValueListenableBuilder<List<LocalAlert>>(
      valueListenable: AdminNotificationService.alertsNotifier,
      builder: (context, alerts, _) {
        // Filter out non ESP offline alerts if the user wants strictly ESP offline
        // But the previous implementation already handles `isSuperAdmin` bypassing sensors!
        final filteredAlerts = alerts.toList();

        if (filteredAlerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
                SizedBox(height: 16),
                Text('Sistem Berjalan Normal', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredAlerts.length,
          itemBuilder: (context, index) {
            final alert = filteredAlerts[index];
            return _buildAlertCard(alert);
          },
        );
      },
    );
  }

  Widget _buildAlertCard(LocalAlert alert) {
    Color iconColor;
    Color cardColor;
    IconData icon;

    switch (alert.severity) {
      case 'danger':
        iconColor = Colors.red;
        cardColor = Colors.red.withOpacity(0.05);
        icon = Icons.error_outline;
        break;
      case 'warning':
        iconColor = Colors.orange;
        cardColor = Colors.orange.withOpacity(0.05);
        icon = Icons.warning_amber_rounded;
        break;
      default:
        iconColor = Colors.blue;
        cardColor = Colors.blue.withOpacity(0.05);
        icon = Icons.info_outline;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: iconColor.withOpacity(0.4), width: 1.5),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Text(alert.message, style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'Poppins', color: Colors.black87)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd MMM yyyy, HH:mm').format(alert.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ============== TAB 2: USER ACTIVITY =================
  Widget _buildUserActivityTab() {
    if (_activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada aktivitas user terbaru', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final act = _activities[index];
        final type = act['activity_type'];

        if (type == 'deposit') {
          return _buildDepositActivity(act);
        } else {
          return _buildRewardActivity(act);
        }
      },
    );
  }

  Widget _buildDepositActivity(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final userEmail = data['userEmail'] ?? 'User';
    final weight = data['weight']?.toString() ?? '0';
    final points = data['pointsEarned']?.toString() ?? '0';
    
    final rawTime = data['createdAt'];
    DateTime time = DateTime.now();
    if (rawTime is Timestamp) time = rawTime.toDate();
    else if (rawTime is String) time = DateTime.tryParse(rawTime) ?? time;

    IconData icon = Icons.inventory_2;
    Color color = Colors.orange;
    String statusStr = 'Mengajukan Setoran';

    if (status == 'approved') {
      icon = Icons.check_circle;
      color = Colors.green;
      statusStr = 'Setoran Disetujui';
    } else if (status == 'rejected') {
      icon = Icons.cancel;
      color = Colors.red;
      statusStr = 'Setoran Ditolak';
    }

    return _buildActivityCard(
      icon: icon,
      color: color,
      title: '$userEmail - $statusStr',
      subtitle: status == 'approved' ? 'Berhasil menyetorkan $weight kg (+$points Pts)' : 'Setoran seberat $weight kg (${status.toUpperCase()})',
      time: time,
    );
  }

  Widget _buildRewardActivity(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final userEmail = data['userEmail'] ?? 'User';
    final rewardName = data['rewardName'] ?? 'Hadiah';
    final points = data['pointsSpent']?.toString() ?? '0';
    
    final rawTime = data['createdAt'];
    DateTime time = DateTime.now();
    if (rawTime is Timestamp) time = rawTime.toDate();
    else if (rawTime is String) time = DateTime.tryParse(rawTime) ?? time;

    IconData icon = Icons.card_giftcard;
    Color color = Colors.purple;
    String statusStr = 'Mengklaim Hadiah';

    if (status == 'approved') {
      icon = Icons.check_circle;
      color = Colors.green;
      statusStr = 'Klaim Disetujui';
    } else if (status == 'rejected') {
      icon = Icons.cancel;
      color = Colors.red;
      statusStr = 'Klaim Ditolak';
    }

    return _buildActivityCard(
      icon: icon,
      color: color,
      title: '$userEmail - $statusStr',
      subtitle: status == 'approved' ? 'Telah mengambil "$rewardName" (-$points Pts)' : 'Permintaan "$rewardName" (${status.toUpperCase()})',
      time: time,
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required DateTime time,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins', color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd MMM yyyy, HH:mm').format(time), style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
