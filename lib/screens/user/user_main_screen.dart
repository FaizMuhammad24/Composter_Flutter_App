import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'user_dashboard.dart';
import 'user_history_screen.dart';
import 'user_profile_screen.dart';
import 'widgets/user_bottom_nav.dart';

class UserMainScreen extends StatefulWidget {
  final UserModel user;
  
  const UserMainScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      UserDashboard(user: widget.user),
      const UserHistoryScreen(),
      const UserProfileScreen(),
    ];

    // Determine background color for nav bar based on active screen
    // UserDashboard has a beige/white bottom gradient, others have their own backgrounds
    Color navBackgroundColor;
    if (_currentIndex == 0) {
      navBackgroundColor = Colors.transparent; 
    } else if (_currentIndex == 1) {
      navBackgroundColor = Colors.white; // UserHistoryScreen is white/primary
    } else {
      navBackgroundColor = const Color(0xFFE8F5E9); // UserProfileScreen bg matches this
    }

    return Scaffold(
      extendBody: true, // Important for transparent/curved nav bar
      body: pages[_currentIndex],
      bottomNavigationBar: UserBottomNav(
        currentIndex: _currentIndex,
        backgroundColor: navBackgroundColor,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
