import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LocalMediaService {
  static const String folderName = 'pawsncare';

  /// Get the dedicated pawsncare directory on the local device.
  static Future<Directory> getPawsNCareDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final pawsDir = Directory('${docsDir.path}/$folderName');
    if (!await pawsDir.exists()) {
      await pawsDir.create(recursive: true);
    }
    return pawsDir;
  }

  /// Save a media file into the local pawsncare directory.
  static Future<File> saveToPawsNCareDirectory(File sourceFile, {String? customFileName}) async {
    final pawsDir = await getPawsNCareDirectory();
    final fileName = customFileName ??
        'media_${DateTime.now().millisecondsSinceEpoch}_${sourceFile.path.split('/').last.split('\\').last}';
    final targetPath = '${pawsDir.path}/$fileName';
    return await sourceFile.copy(targetPath);
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
      return NetworkImage(cleanPath);
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
      return Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
      );
    }

    final cleanPath = path.trim();

    if (cleanPath.startsWith('assets/')) {
      return Image.asset(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    final file = File(cleanPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    // Secondary device or missing file: show fallback asset
    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
