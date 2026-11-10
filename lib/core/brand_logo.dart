import 'package:flutter/material.dart';

/// Original supplied artwork, always contained without cropping or recoloring.
class DaryeelLogo extends StatelessWidget {
  final double size;
  const DaryeelLogo({super.key, this.size = 260});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: size, maxHeight: size),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/branding/daryeel-logo.png',
          fit: BoxFit.contain,
          semanticLabel: 'Daryeel',
          filterQuality: FilterQuality.medium,
        ),
      ),
    ),
  );
}
