import 'package:flutter/material.dart';
import '../core/theme/aurora_theme.dart';

class DropZone extends StatefulWidget {
  final Widget child;
  final void Function(List<String> filePaths)? onFilesDropped;

  const DropZone({
    super.key,
    required this.child,
    this.onFilesDropped,
  });

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isDragging)
          Positioned.fill(
            child: Container(
              color: AuroraColors.deepSpace.withValues(alpha: 0.85),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AuroraColors.auroraTeal,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: AuroraColors.surface.withValues(alpha: 0.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AuroraColors.accentGradient.createShader(bounds),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Drop ebook files here',
                        style: TextStyle(
                          color: AuroraColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'EPUB, PDF, TXT and more',
                        style: TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
