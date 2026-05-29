import 'dart:ui';
import 'package:flutter/material.dart';
import 'aurora_theme.dart';

/// Frosted glass card with blur effect
class AuroraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double blurAmount;

  const AuroraCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.blurAmount = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuroraColors.surface.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Aurora gradient button with glow
class AuroraButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final IconData? icon;
  final bool compact;

  const AuroraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = const LinearGradient(
      colors: [AuroraColors.auroraTeal, AuroraColors.auroraGreen],
    ),
    this.icon,
    this.compact = false,
  });

  @override
  State<AuroraButton> createState() => _AuroraButtonState();
}

class _AuroraButtonState extends State<AuroraButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 16 : 24,
            vertical: widget.compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            gradient: disabled ? null : widget.gradient,
            color: disabled ? AuroraColors.surface : null,
            borderRadius: BorderRadius.circular(100),
            boxShadow: _hovering && !disabled
                ? [
                    BoxShadow(
                      color: AuroraColors.auroraTeal.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AuroraColors.auroraTeal.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
          ),
          transform: _hovering && !disabled
              ? (Matrix4.identity()..scale(1.03))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: disabled
                      ? AuroraColors.textTertiary
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: widget.compact ? 13 : 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated aurora background with layered glows
class AuroraBackground extends StatelessWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D0D28),
                AuroraColors.deepSpace,
                Color(0xFF080818),
              ],
            ),
          ),
        ),
        Positioned(
          left: -120,
          top: -180,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuroraColors.auroraGreen.withOpacity(0.15),
                  AuroraColors.auroraGreen.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -60,
          top: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuroraColors.auroraBlue.withOpacity(0.12),
                  AuroraColors.auroraBlue.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -80,
          bottom: -120,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuroraColors.auroraPurple.withOpacity(0.12),
                  AuroraColors.auroraPurple.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -40,
          bottom: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuroraColors.auroraTeal.withOpacity(0.08),
                  AuroraColors.auroraTeal.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Filter chip styled for Aurora theme
class AuroraFilterChip extends StatefulWidget {
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
  State<AuroraFilterChip> createState() => _AuroraFilterChipState();
}

class _AuroraFilterChipState extends State<AuroraFilterChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.isSelected ? AuroraColors.accentGradient : null,
            color: widget.isSelected
                ? null
                : _hovering
                    ? AuroraColors.surfaceElevated
                    : AuroraColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(100),
            border: widget.isSelected
                ? null
                : Border.all(
                    color: Colors.white.withOpacity(_hovering ? 0.15 : 0.06),
                    width: 0.5,
                  ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected ? Colors.white : AuroraColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
