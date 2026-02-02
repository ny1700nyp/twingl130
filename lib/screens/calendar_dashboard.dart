import 'package:flutter/material.dart';

import 'calendar_tab_screen.dart';

/// KakaoTalk-style tab: Calendar dashboard.
class CalendarDashboard extends StatelessWidget {
  final int refreshToken;

  const CalendarDashboard({
    super.key,
    required this.refreshToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Calendar'),
      ),
      body: SafeArea(child: CalendarTabScreen(refreshToken: refreshToken)),
    );
  }
}

