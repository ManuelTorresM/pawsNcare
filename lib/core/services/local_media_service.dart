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
          return 'https://drive.google.com/thumbnail?id=$id&sz=w1000';
        }
      }
    }
    return clean;
  }

  /// Safely resolve an ImageProvider for any path string (asset, URL, or local file).
  /// If a local file path does not exist on the current device, returns the fallback asset.
  static ImageProvider resolveImageProvider(
    String? path, {
    String fallbackAsset = 'assets/avatars/dog.png',
  }) {
    if (path == null || path.trim().isEmpty) {
      return AssetImage(fallbackAsset);
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

    // If file does not exist locally on this device, return fallback asset gracefully.
    return AssetImage(fallbackAsset);
  }

  /// Helper widget that renders an Image widget safely with fallback support.
  static Widget buildSmartImage({
    required String? path,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String fallbackAsset = 'assets/avatars/dog.png',
  }) {
    if (path == null || path.trim().isEmpty) {
      return Image.asset(fallbackAsset, width: width, height: height, fit: fit);
    }

    final cleanPath = path.trim();

    if (cleanPath.startsWith('assets/')) {
      return Image.asset(cleanPath, width: width, height: height, fit: fit);
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        formatDirectImageUrl(cleanPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset(fallbackAsset, width: width, height: height, fit: fit),
      );
    }

    final file = File(cleanPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset(fallbackAsset, width: width, height: height, fit: fit),
      );
    }

    // Secondary device or missing file: show fallback asset
    return Image.asset(fallbackAsset, width: width, height: height, fit: fit);
  }
}
