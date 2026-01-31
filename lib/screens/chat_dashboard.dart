import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

/// KakaoTalk-style tab: Chat list (Dashboard).
class ChatDashboard extends StatelessWidget {
  final int? resetToken;

  const ChatDashboard({super.key, this.resetToken});

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(resetToken: resetToken, showBackButton: false);
  }
}

