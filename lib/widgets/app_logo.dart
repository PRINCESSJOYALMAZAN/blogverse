import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.iconSize = 32,
  });

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/blogverse-logo.png',
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
    );
  }
}
