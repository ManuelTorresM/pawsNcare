import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveService {
  static const String _keyIsLinked = 'google_drive_linked';
  static const String _keyDriveEmail = 'google_drive_email';
  static const String _folderName = 'PawsNCare_Media';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  /// Check if Google Drive is currently linked.
  static Future<bool> isDriveLinked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLinked) ?? false;
  }

  /// Get the linked Google Drive account email if available.
  static Future<String?> getLinkedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriveEmail);
  }

  /// Link Google Drive account (works for both Google Auth and Email/Password users).
  static Future<bool> linkGoogleDrive() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLinked, true);
      await prefs.setString(_keyDriveEmail, account.email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unlink Google Drive account.
  static Future<void> unlinkGoogleDrive() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLinked, false);
    await prefs.remove(_keyDriveEmail);
  }

  /// Get or create the 'PawsNCare_Media' folder in Google Drive.
  static Future<String?> _getOrCreateDriveFolder(drive.DriveApi driveApi) async {
    try {
      final query = "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName' and trashed = false";
      final list = await driveApi.files.list(q: query);
      if (list.files != null && list.files!.isNotEmpty) {
        return list.files!.first.id;
      }

      final folderToCreate = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final created = await driveApi.files.create(folderToCreate);
      return created.id;
    } catch (e) {
      return null;
    }
  }

  /// Upload a local media file to Google Drive and return the web link or file ID path.
  static Future<String?> uploadImageToDrive(File file) async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) return null;

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) return null;

      final driveApi = drive.DriveApi(authClient);
      final folderId = await _getOrCreateDriveFolder(driveApi);

      final fileName = 'pet_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last.split('\\').last}';

      final driveFile = drive.File()
        ..name = fileName
        ..parents = folderId != null ? [folderId] : null;

      final media = drive.Media(file.openRead(), file.lengthSync());
      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      if (uploadedFile.id != null) {
        // Return web view or direct link format
        return 'https://drive.google.com/uc?id=${uploadedFile.id}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
