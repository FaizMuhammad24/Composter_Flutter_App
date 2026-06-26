import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../services/notifications/management_notification_service.dart';
import '../../../services/notifications/admin_notification_service.dart';
import '../../../models/app_notification_model.dart';

class AdminSystemNotificationsScreen extends StatefulWidget {
  const AdminSystemNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSystemNotificationsScreen> createState() => _AdminSystemNotificationsScreenState();
}

class _AdminSystemNotificationsScreenState extends State<AdminSystemNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Fitlers for each tab
  String _sysFilter = 'Semua'; 
  String _mgtFilter = 'Semua';

  // Streams for user activities
  StreamSubscription? _depSub;
  StreamSubscription? _claimSub;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _depList = [];
  List<Map<String, dynamic>> _claimList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      
      if (valA is Timestamp) {
        dateA = valA.toDate();
      } else if (valA is String) {
        dateA = DateTime.tryParse(valA) ?? dateA;
      }
      
      if (valB is Timestamp) {
        dateB = valB.toDate();
      } else if (valB is String) {
        dateB = DateTime.tryParse(valB) ?? dateB;
      }

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
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        title: const Text(
          'Aktivitas & Notifikasi',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.adminPrimary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () async {
              AdminNotificationService().markAllAsRead();
              await ManagementNotificationService.markAllAsRead();
              if (!mounted) return;
              setState(() {});
            },
            child: const Text('Baca Semua',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Hapus Semua',
            onPressed: () => _showDeleteAllDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Sistem'),
            Tab(text: 'Manajemen'),
            Tab(text: 'Aktiv. User'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSystemTab(),
          _buildManagementTab(),
          _buildUserActivityTab(),
        ],
      ),
    );
  }

  // ==================== TABS ====================
  Widget _buildSystemTab() {
    return ValueListenableBuilder<List<LocalAlert>>(
      valueListenable: AdminNotificationService.alertsNotifier,
      builder: (context, localAlerts, child) {
        final filteredLocalAlerts = localAlerts.where((a) => a.severity != 'info').toList();
        filteredLocalAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final filtered = filteredLocalAlerts.where((alert) {
          if (_sysFilter == 'Belum Dibaca') return !alert.isRead;
          if (_sysFilter == 'Sudah Dibaca') return alert.isRead;
          return true;
        }).toList();

        return Column(
          children: [
            _buildFilterTabs(
              currentFilter: _sysFilter,
              onFilterChanged: (val) => setState(() => _sysFilter = val)
            ),
            Expanded(
              child: filtered.isEmpty
                ? _buildEmptyState('Sistem Berjalan Normal', Icons.check_circle_outline, Colors.green)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildAlertCard(filtered[index]);
                    },
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagementTab() {
    return StreamBuilder<List<AppNotificationModel>>(
      stream: ManagementNotificationService.getNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final firestoreNotifications = snapshot.data ?? [];
        firestoreNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final filtered = firestoreNotifications.where((alert) {
          if (_mgtFilter == 'Belum Dibaca') return !alert.isRead;
          if (_mgtFilter == 'Sudah Dibaca') return alert.isRead;
          return true;
        }).toList();

        return Column(
          children: [
            _buildFilterTabs(
              currentFilter: _mgtFilter,
              onFilterChanged: (val) => setState(() => _mgtFilter = val)
            ),
            Expanded(
              child: filtered.isEmpty
                ? _buildEmptyState('Tidak ada notifikasi baru', Icons.done_all, Colors.grey)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildAdminNotificationCard(filtered[index]);
                    },
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserActivityTab() {
    if (_activities.isEmpty) {
      return _buildEmptyState('Belum ada aktivitas user terbaru', Icons.history_toggle_off, Colors.grey);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
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

  // ==================== COMPONENTS ====================
  Widget _buildFilterTabs({required String currentFilter, required Function(String) onFilterChanged}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['Semua', 'Belum Dibaca', 'Sudah Dibaca'].map((cat) {
          final isSelected = currentFilter == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.adminPrimary,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              onSelected: (_) => onFilterChanged(cat),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: color),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  // ==================== CARDS ====================
  Widget _buildAlertCard(LocalAlert alert) {
    Color iconColor;
    IconData icon;

    switch (alert.severity) {
      case 'danger':
        iconColor = Colors.red;
        icon = Icons.error_outline;
        break;
      case 'warning':
        iconColor = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        iconColor = Colors.blue;
        icon = Icons.info_outline;
    }

    return _buildGlobalCard(
      id: alert.id,
      keyPrefix: 'local',
      icon: icon,
      color: iconColor,
      title: alert.title,
      subtitle: alert.message,
      time: alert.timestamp,
      isRead: alert.isRead,
      onTap: () {
        AdminNotificationService().markAsRead(alert.id);
        setState(() {});
      },
      onDismissed: () => AdminNotificationService().deleteAlert(alert.id),
    );
  }

  Widget _buildAdminNotificationCard(AppNotificationModel alert) {
    Color iconColor;
    IconData icon;

    switch (alert.type) {
      case 'deposit_pending':
        iconColor = Colors.orange;
        icon = Icons.inventory_2;
        break;
      case 'reward_request':
        iconColor = Colors.purple;
        icon = Icons.card_giftcard;
        break;
      case 'system_alert':
        iconColor = Colors.red;
        icon = Icons.error_outline;
        break;
      default:
        iconColor = Colors.blue;
        icon = Icons.info_outline;
    }

    return _buildGlobalCard(
      id: alert.id,
      keyPrefix: 'firestore',
      icon: icon,
      color: iconColor,
      title: alert.title,
      subtitle: alert.message,
      time: alert.createdAt,
      isRead: alert.isRead,
      onTap: () => ManagementNotificationService.markAsRead(alert.id),
      onDismissed: () => ManagementNotificationService.deleteNotification(alert.id),
    );
  }

  Widget _buildDepositActivity(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final userEmail = data['userEmail'] ?? 'User';
    final weight = data['weight']?.toString() ?? '0';
    final points = data['pointsEarned']?.toString() ?? '0';
    
    final rawTime = data['createdAt'];
    DateTime time = DateTime.now();
    if (rawTime is Timestamp) {
      time = rawTime.toDate();
    } else if (rawTime is String) {
      time = DateTime.tryParse(rawTime) ?? time;
    }

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

    return _buildGlobalCard(
      id: data['doc_id'] ?? DateTime.now().toString(),
      keyPrefix: 'deposit',
      icon: icon,
      color: color,
      title: statusStr,
      subtitle: '$userEmail\n${status == 'approved' ? 'Berhasil menyetorkan $weight kg (+$points Pts)' : 'Setoran seberat $weight kg (${status.toUpperCase()})'}',
      time: time,
      isRead: true, // Activities don't have read state, consider them read
      onTap: null,
      onDismissed: null, // History cannot be swiped away here
    );
  }

  Widget _buildRewardActivity(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final userEmail = data['userEmail'] ?? 'User';
    final rewardName = data['rewardName'] ?? 'Hadiah';
    final points = data['pointsSpent']?.toString() ?? '0';
    
    final rawTime = data['createdAt'];
    DateTime time = DateTime.now();
    if (rawTime is Timestamp) {
      time = rawTime.toDate();
    } else if (rawTime is String) {
      time = DateTime.tryParse(rawTime) ?? time;
    }

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

    return _buildGlobalCard(
      id: data['doc_id'] ?? DateTime.now().toString(),
      keyPrefix: 'reward',
      icon: icon,
      color: color,
      title: statusStr,
      subtitle: '$userEmail\n${status == 'approved' ? 'Telah mengambil "$rewardName" (-$points Pts)' : 'Permintaan "$rewardName" (${status.toUpperCase()})'}',
      time: time,
      isRead: true,
      onTap: null,
      onDismissed: null,
    );
  }

  // UNIFIED CARD WIDGET
  Widget _buildGlobalCard({
    required String id,
    required String keyPrefix,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required DateTime time,
    required bool isRead,
    Function()? onTap,
    Function()? onDismissed,
  }) {
    Color cardColor = color.withValues(alpha: 0.05);

    Widget cardBody = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isRead ? Colors.grey.withValues(alpha: 0.3) : color.withValues(alpha: 0.4), 
            width: 1.5
          ),
        ),
        color: isRead ? Colors.white : cardColor,
        child: Stack(
          children: [
            // Indicator line on the left side
            Positioned(
              left: 0, top: 0, bottom: 0,
              width: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: color, 
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16))
                )
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 22, right: 16, top: 16, bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey.withValues(alpha: 0.1) : color.withValues(alpha: 0.15), 
                      shape: BoxShape.circle
                    ), 
                    child: Icon(icon, color: isRead ? Colors.grey[600] : color, size: 24)
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, fontSize: 14, fontFamily: 'Poppins', color: isRead ? Colors.black54 : Colors.black87)),
                        const SizedBox(height: 6),
                        Text(subtitle, style: TextStyle(fontSize: 12, height: 1.4, fontFamily: 'Poppins', color: isRead ? Colors.black54 : Colors.grey[700])),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(DateFormat('dd MMM yyyy • HH:mm').format(time), style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onDismissed != null) {
      return Dismissible(
        key: Key('${keyPrefix}_$id'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => onDismissed(),
        child: cardBody,
      );
    }

    return cardBody;
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus semua notifikasi ini secara permanen?', style: TextStyle(fontFamily: 'Poppins')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              AdminNotificationService().clearAll();
              await ManagementNotificationService.deleteAllNotifications();
              if (!mounted) return;
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Semua', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}
