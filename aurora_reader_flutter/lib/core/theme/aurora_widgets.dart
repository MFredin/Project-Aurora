import 'dart:ui';
import 'package:flutter/material.dart';
import 'aurora_theme.dart';

/// Stone tablet card with subtle grain texture
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
    this.blurAmount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuroraColors.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3A3530),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Hammered metal button with amber glow
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
      colors: [Color(0xFFC4973B), Color(0xFFA8802E)],
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
            borderRadius: BorderRadius.circular(8),
            border: disabled
                ? Border.all(color: const Color(0xFF3A3530), width: 0.5)
                : null,
            boxShadow: _hovering && !disabled
                ? [
                    BoxShadow(
                      color: AuroraColors.auroraTeal.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          transform: _hovering && !disabled
              ? (Matrix4.identity()..scale(1.02))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: disabled
                        ? AuroraColors.textTertiary
                        : const Color(0xFFFFF5E0),
                    size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: disabled
                      ? AuroraColors.textTertiary
                      : const Color(0xFFFFF5E0),
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

/// Nordic night background with subtle warm undertones
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
                Color(0xFF1E1C1A),
                AuroraColors.deepSpace,
                Color(0xFF141210),
              ],
            ),
          ),
        ),
        // Warm firelight glow from below
        Positioned(
          left: -80,
          bottom: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuroraColors.auroraTeal.withOpacity(0.06),
                  AuroraColors.auroraTeal.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Cold frost hint from top right
        Positioned(
          right: -100,
          top: -120,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AuroraColors.auroraBlue.withOpacity(0.05),
                  AuroraColors.auroraBlue.withOpacity(0.0),
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

/// Runestone-style filter chip
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
                    : AuroraColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? null
                : Border.all(
                    color: Color.lerp(
                      const Color(0xFF3A3530),
                      const Color(0xFF4A4540),
                      _hovering ? 1.0 : 0.0,
                    )!,
                    width: 0.5,
                  ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? const Color(0xFFFFF5E0)
                  : AuroraColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
