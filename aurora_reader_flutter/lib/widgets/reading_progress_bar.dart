import 'package:flutter/material.dart';
import '../core/theme/aurora_theme.dart';

/// Thin gradient progress indicator.
class ReadingProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Gradient? gradient;

  const ReadingProgressBar({
    super.key,
    required this.progress,
    this.height = 4,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AuroraColors.surface,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: gradient ?? AuroraColors.accentGradient,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
