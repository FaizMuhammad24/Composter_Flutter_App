import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../admin_notifications_screen.dart';
import '../../../services/notifications/admin_notification_service.dart';

class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AdminHeader({Key? key, this.title = 'Admin i-Composter'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.adminPrimary,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      leading: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield, color: AppColors.adminPrimary, size: 20),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        ValueListenableBuilder<List<LocalAlert>>(
          valueListenable: AdminNotificationService.alertsNotifier,
          builder: (context, alerts, _) {
            final unreadCount = alerts.where((a) => !a.isRead).length;
            return IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: Colors.white),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
