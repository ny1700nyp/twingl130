import 'package:flutter/material.dart';

import 'calendar_tab_screen.dart';

/// KakaoTalk-style tab: Calendar dashboard.
class CalendarDashboard extends StatelessWidget {
  const CalendarDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Calendar'),
      ),
      body: const SafeArea(child: CalendarTabScreen()),
    );
  }
}

