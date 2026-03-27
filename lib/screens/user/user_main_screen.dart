import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'user_dashboard.dart';
import 'user_history_screen.dart';
import 'user_profile_screen.dart';
import 'widgets/user_bottom_nav.dart';
import '../../services/notifications/user_notification_service.dart';

class UserMainScreen extends StatefulWidget {
  final UserModel user;
  
  const UserMainScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    UserNotificationService.initPushNotifications(widget.user.email);
    _pages = [
      UserDashboard(user: widget.user),
      UserHistoryScreen(user: widget.user),
      UserProfileScreen(user: widget.user),
    ];
  }

  @override
  void dispose() {
    UserNotificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The bottom edge of ALL user screens is white (either scrollable content
    // or the profile's white rounded panel). Use white consistently so the
    // CurvedNavigationBar drop/wave effect always renders correctly.
    const navBgColor = Colors.white;

    return Scaffold(
      // Match the nav bg so the curve blends in on all tabs.
      backgroundColor: navBgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: UserBottomNav(
        currentIndex: _currentIndex,
        backgroundColor: navBgColor,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
