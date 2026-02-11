import 'package:flutter/material.dart';
import 'aurora_theme.dart';

/// Aurora-styled card with frosted glass border
class AuroraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AuroraCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuroraColors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Aurora gradient button (capsule shape)
class AuroraButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final LinearGradient gradient;
  final IconData? icon;

  const AuroraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = const LinearGradient(
      colors: [AuroraColors.auroraTeal, AuroraColors.auroraGreen],
    ),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AuroraColors.auroraTeal.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aurora background with blurred gradient circles
class AuroraBackground extends StatelessWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AuroraColors.deepSpace),
        // Top-left green/teal glow
        Positioned(
          left: -100,
          top: -200,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraColors.auroraGreen.withOpacity(0.12),
            ),
          ),
        ),
        // Center blue glow
        Positioned(
          left: 50,
          top: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraColors.auroraBlue.withOpacity(0.10),
            ),
          ),
        ),
        // Bottom-right purple glow
        Positioned(
          right: -50,
          bottom: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraColors.auroraPurple.withOpacity(0.10),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Filter chip styled for Aurora theme
class AuroraFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AuroraFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AuroraColors.accentGradient : null,
          color: isSelected ? null : AuroraColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AuroraColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
