import 'package:flutter/material.dart';
import '../core/theme/aurora_theme.dart';
import '../core/theme/aurora_widgets.dart';

/// Compact stat display with icon, value, and label.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AuroraColors.auroraTeal,
  });

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuroraColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
