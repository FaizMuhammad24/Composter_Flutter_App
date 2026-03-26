import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../user_notifications_screen.dart';
import '../../../services/notifications/app_notification_service.dart';

class UserHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userEmail;
  const UserHeader({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(Icons.eco, color: Colors.white, size: 28),
      ),
      title: const Text(
        'I-Compost',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        StreamBuilder<int>(
          stream: AppNotificationService.getUnreadCountStream(userEmail),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
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
                          minWidth: 12,
                          minHeight: 12,
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
                  MaterialPageRoute(
                    builder: (_) => UserNotificationsScreen(userEmail: userEmail),
                  ),
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
