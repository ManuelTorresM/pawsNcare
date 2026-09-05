import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LocalMediaService {
  static const String folderName = 'pawsncare';

  /// Get the dedicated pawsncare directory on the local device (Publicly visible in Gallery/Files).
  static Future<Directory> getPawsNCareDirectory() async {
    Directory targetDir;
    if (Platform.isAndroid) {
      // Use public Pictures directory on Android so images appear in Gallery & File Manager
      targetDir = Directory('/storage/emulated/0/Pictures/$folderName');
      if (!await targetDir.exists()) {
        try {
          await targetDir.create(recursive: true);
        } catch (_) {
          final extDir = await getExternalStorageDirectory();
          targetDir = Directory('${extDir?.path ?? ''}/$folderName');
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
        }
      }
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${docsDir.path}/$folderName');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
    }
    return targetDir;
  }

  /// Save a media file into the local pawsncare directory.
  static Future<File> saveToPawsNCareDirectory(
    File sourceFile, {
    String? customFileName,
  }) async {
    final pawsDir = await getPawsNCareDirectory();
    final fileName =
        customFileName ??
        'media_${DateTime.now().millisecondsSinceEpoch}_${sourceFile.path.split('/').last.split('\\').last}';
    final targetPath = '${pawsDir.path}/$fileName';
    return await sourceFile.copy(targetPath);
  }

  /// Transforms Google Drive web view URLs into direct binary JPEG image thumbnail URLs
  /// so Android ImageDecoder receives valid byte streams without HTML redirects.
  static String formatDirectImageUrl(String url) {
    final clean = url.trim();
    if (clean.contains('drive.google.com') && clean.contains('id=')) {
      final uri = Uri.tryParse(clean);
      if (uri != null && uri.queryParameters.containsKey('id')) {
        final id = uri.queryParameters['id'];
        if (id != null && id.isNotEmpty) {
          return 'https://drive.google.com/uc?export=download&id=$id';
        }
      }
    }
    return clean;
  }

  /// Safely resolve an ImageProvider for any path string (asset, URL, or local file).
  /// If a local file path does not exist on the current device, returns optional fallbackAsset or null.
  static ImageProvider? resolveImageProvider(
    String? path, {
    String? fallbackAsset,
  }) {
    if (path == null || path.trim().isEmpty) {
      return fallbackAsset != null ? AssetImage(fallbackAsset) : null;
    }

    final cleanPath = path.trim();

    if (cleanPath.startsWith('assets/')) {
      return AssetImage(cleanPath);
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return NetworkImage(formatDirectImageUrl(cleanPath));
    }

    final file = File(cleanPath);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return fallbackAsset != null ? AssetImage(fallbackAsset) : null;
  }

  /// Helper widget that renders an Image widget safely with flexible fallback support.
  static Widget buildSmartImage({
    required String? path,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? fallbackAsset,
    Widget? fallbackWidget,
  }) {
    Widget getFallback() {
      if (fallbackWidget != null) return fallbackWidget;
      if (fallbackAsset != null && fallbackAsset.isNotEmpty) {
        return Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
        );
      }
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE0E0E0),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey.shade600,
            size: (width != null && width < 50) ? 20 : 32,
          ),
        ),
      );
    }

    if (path == null || path.trim().isEmpty) {
      return getFallback();
    }

    final cleanPath = path.trim();

    if (cleanPath.startsWith('assets/')) {
      return Image.asset(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => getFallback(),
      );
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        formatDirectImageUrl(cleanPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => getFallback(),
      );
    }

    final file = File(cleanPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => getFallback(),
      );
    }

    return getFallback();
  }
}
