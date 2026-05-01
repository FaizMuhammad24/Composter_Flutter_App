import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../services/notifications/admin_notification_service.dart';
import '../../../services/notifications/super_admin_notification_service.dart';
import '../super_admin_notifications_screen.dart';


class SuperAdminHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String adminEmail;
  const SuperAdminHeader({Key? key, this.title = 'Super Admin', required this.adminEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.superAdminPrimary,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
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
          builder: (context, localAlerts, _) {
            final unreadLocal = localAlerts.where((a) => !a.isRead && a.severity != 'info').length;
            return StreamBuilder<int>(
              stream: SuperAdminNotificationService.getUnreadCountStream(),
              builder: (context, snapshot) {
                final unreadFirestore = snapshot.data ?? 0;
                final totalCount = unreadLocal + unreadFirestore;
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined, color: Colors.white),
                      if (totalCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              totalCount > 9 ? '9+' : totalCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SuperAdminNotificationsScreen(adminEmail: adminEmail),
                      ),
                    );
                  },
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
