import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TwinglWordmark extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;

  const TwinglWordmark({
    super.key,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleLarge;
    return Text(
      'Twingl',
      style: (base ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: AppTheme.twinglGreen,
      ),
    );
  }
}

