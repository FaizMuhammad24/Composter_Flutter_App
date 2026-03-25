import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/app_notification_model.dart';
import '../../services/notifications/app_notification_service.dart';
import 'package:intl/intl.dart';

class UserNotificationsScreen extends StatefulWidget {
  final String userEmail;
  const UserNotificationsScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<UserNotificationsScreen> createState() => _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when opened
    AppNotificationService.markAllAsRead(widget.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar abu-abu sangat muda agar kartu notif menonjol
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Tombol back warna putih
      ),
      body: StreamBuilder<List<AppNotificationModel>>(
        stream: AppNotificationService.getUserNotificationsStream(widget.userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada notifikasi.',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
              ),
            );
          }

          final notifications = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationCard(
                title: notif.title,
                description: notif.message,
                date: DateFormat('dd MMM yyyy • HH:mm').format(notif.createdAt),
                type: notif.type,
                isUnread: notif.isRead == false,
                onTap: () {
                  if (!notif.isRead) {
                    AppNotificationService.markAsRead(notif.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required String date,
    required String type,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    IconData icon;
    Color iconColor;
    Color backgroundColor;

    switch (type) {
      case 'success':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'error':
        icon = Icons.cancel;
        iconColor = Colors.red;
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'reward':
        icon = Icons.card_giftcard;
        iconColor = Colors.blue;
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        break;
      case 'system':
      default:
        icon = Icons.warning_rounded;
        iconColor = Colors.orange;
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isUnread ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5) : Border.all(color: Colors.grey[100]!),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Bulat
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Konten Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Indikator Titik Merah Unread
          if (isUnread)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ));
  }
}

