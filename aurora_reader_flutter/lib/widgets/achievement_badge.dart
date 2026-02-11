import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/aurora_theme.dart';

/// Circular achievement badge with locked/unlocked states.
class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isUnlocked;
  final double progress;
  final Color color;

  const AchievementBadge({
    super.key,
    required this.icon,
    required this.title,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.color = AuroraColors.auroraTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              if (!isUnlocked && progress > 0)
                CustomPaint(
                  size: const Size(72, 72),
                  painter: _ProgressRingPainter(
                    progress: progress,
                    color: color,
                  ),
                ),

              // Badge circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? color.withOpacity(0.2)
                      : AuroraColors.surface,
                  border: isUnlocked
                      ? Border.all(color: color.withOpacity(0.6), width: 2)
                      : null,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isUnlocked ? color : AuroraColors.textTertiary,
                  size: 26,
                ),
              ),

              // Lock overlay
              if (!isUnlocked && progress == 0)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AuroraColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AuroraColors.surface,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AuroraColors.textTertiary,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isUnlocked
                ? AuroraColors.textPrimary
                : AuroraColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final bgPaint = Paint()
      ..color = AuroraColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}
