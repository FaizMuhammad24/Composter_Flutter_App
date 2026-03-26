import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/app_notification_model.dart';
import '../../services/notifications/app_notification_service.dart';

class SuperAdminNotificationsScreen extends StatefulWidget {
  final String adminEmail;
  const SuperAdminNotificationsScreen({Key? key, required this.adminEmail}) : super(key: key);

  @override
  State<SuperAdminNotificationsScreen> createState() => _SuperAdminNotificationsScreenState();
}

class _SuperAdminNotificationsScreenState extends State<SuperAdminNotificationsScreen> {
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    // Do not mark all as read automatically, to match Admin behavior
    // AppNotificationService.markAllAsRead(widget.adminEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.superAdminBg,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.superAdminPrimary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () async {
              await AppNotificationService.markAllAsRead(widget.adminEmail);
              setState(() {});
            },
            child: const Text('Baca Semua', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Hapus Semua',
            onPressed: () => _showDeleteAllDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotificationModel>>(
        stream: AppNotificationService.getUserNotificationsStream(widget.adminEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.superAdminPrimary));
          }

          final all = snapshot.data ?? [];
          final filtered = _applyFilter(all);

          return Column(
            children: [
              // Filter Tabs
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Semua', 'Belum Dibaca', 'Sudah Dibaca'].map((cat) {
                    final isSelected = _filter == cat;
                    return InkWell(
                      onTap: () => setState(() => _filter = cat),
                      child: Column(
                        children: [
                          Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? AppColors.superAdminPrimary : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 2,
                            color: isSelected ? AppColors.superAdminPrimary : Colors.transparent,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Notifications Body
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildNotifCard(filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AppNotificationModel> _applyFilter(List<AppNotificationModel> all) {
    switch (_filter) {
      case 'Belum Dibaca':
        return all.where((n) => !n.isRead).toList();
      case 'Sudah Dibaca':
        return all.where((n) => n.isRead).toList();
      default:
        return all;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada notifikasi',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          const Text(
            'Notifikasi setoran dan permintaan\nhadiah user akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(AppNotificationModel notif) {
    IconData icon;
    Color iconColor;
    Color cardColor;

    switch (notif.type) {
      case 'deposit_pending':
        icon = Icons.inventory_2_outlined;
        iconColor = Colors.orange;
        cardColor = Colors.orange.withOpacity(0.05);
        break;
      case 'reward_request':
        icon = Icons.card_giftcard_rounded;
        iconColor = Colors.purple;
        cardColor = Colors.purple.withOpacity(0.05);
        break;
      case 'system_alert':
        icon = Icons.warning_rounded;
        iconColor = Colors.red;
        cardColor = Colors.red.withOpacity(0.05);
        break;
      case 'info':
        icon = Icons.info_outline_rounded;
        iconColor = Colors.blue;
        cardColor = Colors.blue.withOpacity(0.05);
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = Colors.grey;
        cardColor = Colors.grey.withOpacity(0.05);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notif.isRead ? Colors.grey.shade200 : iconColor.withOpacity(0.4),
          width: notif.isRead ? 1 : 1.5,
        ),
      ),
      color: notif.isRead ? Colors.white : cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!notif.isRead) AppNotificationService.markAsRead(notif.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'Poppins', color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(notif.createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Seluruh riwayat notifikasi untuk admin ini akan dihapus permanen.', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await AppNotificationService.deleteAllNotifications(widget.adminEmail);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
