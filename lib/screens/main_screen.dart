import 'package:flutter/material.dart';

import 'calendar_tab_screen.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'profile_home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _chatResetToken = 0;

  @override
  Widget build(BuildContext context) {
    // Important: each tab screen is already a `Scaffold`. Wrapping with another
    // `Scaffold` causes nested scaffolds (weird AppBars/layout). So we layout
    // the tabs + bottom bar directly.
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              const HomeScreen(),
              DashboardScreen(resetToken: _chatResetToken),
              const CalendarTabScreen(),
              const ProfileHomeScreen(),
            ],
          ),
        ),
        BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (idx) {
            setState(() {
              // If we are entering Chat tab from another tab, reset filters.
              if (idx == 1 && _currentIndex != 1) {
                _chatResetToken += 1;
              }
              _currentIndex = idx;
            });
          },
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: '',
            ),
          ],
        ),
      ],
    );
  }
}

