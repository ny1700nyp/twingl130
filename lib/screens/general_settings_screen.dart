import 'package:flutter/material.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Settings'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Coming soon'),
        ),
      ),
    );
  }
}

