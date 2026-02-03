import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'calendar_dashboard.dart';
import 'chat_dashboard.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import '../services/supabase_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _chatResetToken = 0;
  int _calendarRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Ensure badge is correct even before opening Chat tab.
      SupabaseService.getChatConversationsCached(user.id);
    }
  }

  int _totalUnread(List<Map<String, dynamic>>? conversations) {
    if (conversations == null) return 0;
    int total = 0;
    for (final c in conversations) {
      total += (c['unread_count'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  Widget _chatIconWithBadge(int unread) {
    final show = unread > 0;
    final label = unread > 99 ? '99+' : unread.toString();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat_bubble_outline),
        if (show)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          ChatDashboard(resetToken: _chatResetToken),
          CalendarDashboard(refreshToken: _calendarRefreshToken),
          const MoreScreen(),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<List<Map<String, dynamic>>?>(
        valueListenable: SupabaseService.chatConversationsCache,
        builder: (context, convs, _) {
          final unread = _totalUnread(convs);
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (idx) {
              setState(() {
                // If we are entering Chat tab from another tab, reset filters.
                if (idx == 1 && _currentIndex != 1) {
                  _chatResetToken += 1;
                }
                // If we are entering Calendar tab from another tab, refresh events.
                if (idx == 2 && _currentIndex != 2) {
                  _calendarRefreshToken += 1;
                }
                _currentIndex = idx;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _chatIconWithBadge(unread),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz),
                label: '',
              ),
            ],
          );
        },
      ),
    );
  }
}


