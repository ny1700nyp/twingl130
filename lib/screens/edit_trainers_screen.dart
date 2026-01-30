import 'package:flutter/material.dart';

import 'liked_profiles_screen.dart';

/// Legacy/utility screen: currently uses the same UI as favorites list.
class EditTrainersScreen extends StatelessWidget {
  const EditTrainersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LikedProfilesScreen();
  }
}

