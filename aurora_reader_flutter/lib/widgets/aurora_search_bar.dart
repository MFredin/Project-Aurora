import 'package:flutter/material.dart';
import '../core/theme/aurora_theme.dart';

/// Styled search input with Aurora theme.
class AuroraSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final TextEditingController? controller;

  const AuroraSearchBar({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search...',
    this.controller,
  });

  @override
  State<AuroraSearchBar> createState() => _AuroraSearchBarState();
}

class _AuroraSearchBarState extends State<AuroraSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(color: AuroraColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AuroraColors.textTertiary),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AuroraColors.textTertiary),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AuroraColors.textTertiary, size: 20),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
