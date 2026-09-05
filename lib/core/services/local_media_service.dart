import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LocalMediaService {
  static const String folderName = 'pawsncare';

  /// Get the dedicated pawsncare directory on the local device using app storage permissions.
  static Future<Directory> getPawsNCareDirectory() async {
    Directory targetDir;
    try {
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        targetDir = Directory('${extDir?.path ?? ''}/$folderName');
      } else {
        final docsDir = await getApplicationDocumentsDirectory();
        targetDir = Directory('${docsDir.path}/$folderName');
      }
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      return targetDir;
    } catch (_) {
      final docsDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${docsDir.path}/$folderName');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      return targetDir;
    }
  }

  /// Save a media file into the local pawsncare directory.
  static Future<File> saveToPawsNCareDirectory(
    File sourceFile, {
    String? customFileName,
  }) async {
    try {
      final pawsDir = await getPawsNCareDirectory();

      final sourceNormalized = sourceFile.path.replaceAll('\\', '/');
      final pawsNormalized = pawsDir.path.replaceAll('\\', '/');

      // If already inside pawsncare directory, return sourceFile directly
      if (sourceNormalized.startsWith(pawsNormalized) ||
          sourceNormalized.contains('/pawsncare/')) {
        return sourceFile;
      }

      final fileName =
          customFileName ??
          'media_${DateTime.now().millisecondsSinceEpoch}_${sourceFile.path.split('/').last.split('\\').last}';
      final targetPath = '${pawsDir.path}/$fileName';
      return await sourceFile.copy(targetPath);
    } catch (e) {
      debugPrint('saveToPawsNCareDirectory ERROR: $e');
      return sourceFile;
    }
  }

  /// Synchronize an image file or network URL to the local device's pawsncare directory.
  /// - If it's a local file, copies it into the local pawsncare directory.
  /// - If it's a remote URL (HTTP/Drive), downloads it into the local pawsncare directory.
  /// Returns the local File if saved/downloaded successfully, or null otherwise.
  static Future<File?> syncToLocalDirectory(String pathOrUrl) async {
    if (pathOrUrl.trim().isEmpty || pathOrUrl.startsWith('assets/')) {
      return null;
    }

    final clean = pathOrUrl.trim();

    try {
      final pawsDir = await getPawsNCareDirectory();

      // 1. Local File Case
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        final sourceFile = File(clean);
        if (await sourceFile.exists()) {
          return await saveToPawsNCareDirectory(sourceFile);
        }
        return null;
      }

      // 2. Remote URL Case (HTTP / Google Drive)
      final directUrl = formatDirectImageUrl(clean);
      final response = await http
          .get(Uri.parse(directUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html')) {
          debugPrint(
            'syncToLocalDirectory: URL returned HTML, skipping $clean',
          );
          return null;
        }

        final fileName =
            'downloaded_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final localFile = File('${pawsDir.path}/$fileName');
        await localFile.writeAsBytes(response.bodyBytes);
        debugPrint(
          'syncToLocalDirectory: Successfully downloaded $clean -> ${localFile.path}',
        );
        return localFile;
      }
    } catch (e) {
      debugPrint('syncToLocalDirectory ERROR for $pathOrUrl: $e');
    }
    return null;
  }

  /// Transforms Google Drive web view URLs into direct binary JPEG image thumbnail URLs
  /// so Android ImageDecoder receives valid byte streams without HTML redirects.
  static String formatDirectImageUrl(String url) {
    final clean = url.trim();
    if (clean.contains('drive.google.com')) {
      String? id;
      if (clean.contains('id=')) {
        final uri = Uri.tryParse(clean);
        if (uri != null && uri.queryParameters.containsKey('id')) {
          id = uri.queryParameters['id'];
        }
      } else if (clean.contains('/d/')) {
        final parts = clean.split('/d/');
        if (parts.length > 1) {
          id = parts[1].split('/')[0];
        }
      }
      if (id != null && id.isNotEmpty) {
        return 'https://drive.google.com/thumbnail?id=$id&sz=w1000';
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
    if (file.existsSync() && file.lengthSync() > 0) {
      return FileImage(file);
    }

    return fallbackAsset != null ? AssetImage(fallbackAsset) : null;
  }

  /// Helper widget that renders an Image widget safely with flexible fallback support.
  /// When no image is defined or valid, renders a blank card with a paw icon.
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
      // Blank card with a paw icon
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Icon(
            Icons.pets,
            color: Colors.grey.shade400,
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
    if (file.existsSync() && file.lengthSync() > 0) {
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
