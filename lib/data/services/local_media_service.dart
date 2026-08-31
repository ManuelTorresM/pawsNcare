import 'package:shared_preferences/shared_preferences.dart';

class LocalMediaService {
  static const String _avatarPrefix = 'local_avatar_';
  static const String _photosPrefix = 'local_photos_';

  /// Save local avatar file path for a specific pet ID
  static Future<void> saveLocalAvatar(String petId, String avatarPath) async {
    if (petId.isEmpty || avatarPath.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_avatarPrefix$petId', avatarPath);
  }

  /// Retrieve local avatar file path for a pet ID
  static Future<String?> getLocalAvatar(String petId) async {
    if (petId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_avatarPrefix$petId');
  }

  /// Save local photo file paths for a pet ID
  static Future<void> saveLocalPhotos(String petId, List<String> photos) async {
    if (petId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_photosPrefix$petId', photos);
  }

  /// Retrieve local photo file paths for a pet ID
  static Future<List<String>> getLocalPhotos(String petId) async {
    if (petId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$_photosPrefix$petId') ?? [];
  }
}
