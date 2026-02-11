import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/theme/aurora_theme.dart';

/// Book cover widget with image or gradient fallback.
class BookCover extends StatelessWidget {
  final String title;
  final String author;
  final Uint8List? coverImageData;
  final double width;
  final double height;
  final double? progress;
  final double borderRadius;

  const BookCover({
    super.key,
    required this.title,
    required this.author,
    this.coverImageData,
    this.width = 120,
    this.height = 170,
    this.progress,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Cover image or gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: coverImageData != null
                ? Image.memory(
                    coverImageData!,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: AuroraColors.coverGradient(title),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 8, color: Colors.black54),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            author,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              shadows: const [
                                Shadow(blurRadius: 8, color: Colors.black54),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Progress bar at bottom
          if (progress != null && progress! > 0 && progress! < 1.0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(borderRadius),
                ),
                child: LinearProgressIndicator(
                  value: progress!,
                  minHeight: 3,
                  backgroundColor: Colors.black.withOpacity(0.3),
                  valueColor:
                      const AlwaysStoppedAnimation(AuroraColors.auroraTeal),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
