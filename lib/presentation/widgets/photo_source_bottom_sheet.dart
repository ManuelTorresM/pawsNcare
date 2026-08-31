import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class PhotoSourceBottomSheet extends StatelessWidget {
  final String title;
  final ValueChanged<ImageSource> onSourceSelected;

  const PhotoSourceBottomSheet({
    super.key,
    this.title = 'Select Media Source',
    required this.onSourceSelected,
  });

  /// Helper static method to display the modal bottom sheet and return selected [ImageSource].
  static Future<ImageSource?> show(
    BuildContext context, {
    String title = 'Select Media Source',
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PhotoSourceBottomSheet(
        title: title,
        onSourceSelected: (source) => Navigator.of(sheetContext).pop(source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppTheme.darkSurface
        : AppTheme.surfaceContainerLowest;
    final textPrimary = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final textSecondary = isDark
        ? AppTheme.darkOnSurfaceVariant
        : AppTheme.secondary;
    final primaryColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
    final dividerColor = isDark
        ? const Color(0xFF383634)
        : AppTheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.photo_library, color: primaryColor),
            ),
            title: Text(
              'Choose from Gallery',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            onTap: () {
              onSourceSelected(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.photo_camera, color: primaryColor),
            ),
            title: Text(
              'Open Camera',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            onTap: () {
              onSourceSelected(ImageSource.camera);
            },
          ),
          const SizedBox(height: 8),
          Divider(color: dividerColor),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: textSecondary),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
