import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../core/services/local_media_service.dart';

/// Reusable card widget for rendering pet memory photos safely across
/// both network URLs and local file system paths.
class MemoryImageCard extends StatelessWidget {
  final String url;
  final double width;
  final double? height;
  final double borderRadius;
  final VoidCallback? onTap;

  const MemoryImageCard({
    super.key,
    required this.url,
    this.width = 120,
    this.height,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: LocalMediaService.buildSmartImage(
          path: url,
          fit: BoxFit.cover,
          width: width,
          height: height,
          fallbackWidget: Container(
            width: width,
            height: height,
            color: AppTheme.surfaceContainer,
            child: const Center(
              child: Icon(
                Icons.photo,
                color: AppTheme.secondary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
