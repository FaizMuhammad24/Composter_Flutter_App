import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/notifications/admin_notification_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);
  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  String _filter = 'Semua';

  List<LocalAlert> get _filtered {
    final all = AdminNotificationService.alerts;
    if (_filter == 'Belum Dibaca') return all.where((n) => !n.isRead).toList();
    if (_filter == 'Sudah Dibaca') return all.where((n) => n.isRead).toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        title: const Text('Notifikasi',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.adminPrimary,
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              AdminNotificationService().markAllAsRead();
              setState(() {});
            },
            child: const Text('Baca Semua',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Hapus Semua',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Semua?', style: TextStyle(fontFamily: 'Poppins')),
                  content: const Text('Semua riwayat notifikasi lokal akan dihapus permanen.', style: TextStyle(fontFamily: 'Poppins')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                    TextButton(
                      onPressed: () {
                        AdminNotificationService().clearAll();
                        setState(() => Navigator.pop(context));
                      }, 
                      child: const Text('Hapus', style: TextStyle(color: Colors.red))
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
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
                          color: isSelected ? AppColors.adminPrimary : Colors.grey,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 2,
                        color: isSelected
                            ? AppColors.adminPrimary
                            : Colors.transparent,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Notifications List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Tidak ada notifikasi',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('Notifikasi akan muncul saat sensor\nmelewati batas parameter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      return _buildAlertCard(_filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(LocalAlert alert) {
    Color cardColor;
    IconData icon;
    Color iconColor;

    switch (alert.severity) {
      case 'danger':
        cardColor = Colors.red[50]!;
        icon = Icons.warning_rounded;
        iconColor = Colors.red;
        break;
      case 'warning':
        cardColor = Colors.orange[50]!;
        icon = Icons.error_outline_rounded;
        iconColor = Colors.orange;
        break;
      default:
        cardColor = Colors.blue[50]!;
        icon = Icons.info_outline_rounded;
        iconColor = Colors.blue;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: alert.isRead ? Colors.transparent : iconColor.withOpacity(0.3)),
      ),
      color: alert.isRead ? Colors.white : cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(alert.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Poppins')),
            ),
            if (!alert.isRead)
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(alert.message,
                style: const TextStyle(
                    fontSize: 13, height: 1.4, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(alert.timestamp),
              style:
                  const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins'),
            ),
          ],
        ),
        onTap: () => setState(() => alert.isRead = true),
      ),
    );
  }
}
