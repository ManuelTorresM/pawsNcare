import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

class GoogleDriveService {
  static const String _keyIsLinked = 'google_drive_linked';
  static const String _keyDriveEmail = 'google_drive_email';
  static const String _rootFolderName = 'PawsNCare_Media';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static String? lastErrorMessage;

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

  /// Link Google Drive account with driveFileScope authorization.
  static Future<bool> linkGoogleDrive() async {
    lastErrorMessage = null;
    try {
      GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('GoogleDriveService linkGoogleDrive: signIn returned null');
        return false;
      }

      try {
        await _googleSignIn.requestScopes([drive.DriveApi.driveFileScope]);
      } catch (e) {
        debugPrint('GoogleDriveService linkGoogleDrive requestScopes note: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLinked, true);
      await prefs.setString(_keyDriveEmail, account.email);
      debugPrint(
        'GoogleDriveService linkGoogleDrive SUCCESS for email: ${account.email}',
      );
      return true;
    } catch (e, stack) {
      lastErrorMessage = e.toString();
      debugPrint('GoogleDriveService linkGoogleDrive ERROR: $e\n$stack');
      return false;
    }
  }

  /// Unlink Google Drive account.
  static Future<void> unlinkGoogleDrive() async {
    lastErrorMessage = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLinked, false);
    await prefs.remove(_keyDriveEmail);
    debugPrint('GoogleDriveService unlinked Google Drive.');
  }

  /// Get authenticated DriveApi instance.
  static Future<drive.DriveApi?> _getDriveApi() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('GoogleDriveService _getDriveApi: account is null');
        return null;
      }

      try {
        await _googleSignIn.requestScopes([drive.DriveApi.driveFileScope]);
      } catch (e) {
        debugPrint('GoogleDriveService _getDriveApi requestScopes note: $e');
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        debugPrint(
          'GoogleDriveService _getDriveApi: authenticatedClient is null',
        );
        return null;
      }

      return drive.DriveApi(authClient);
    } catch (e, stack) {
      lastErrorMessage = e.toString();
      debugPrint('GoogleDriveService _getDriveApi ERROR: $e\n$stack');
      return null;
    }
  }

  /// Get or create a folder in Google Drive by name under optional parentId.
  static Future<String?> _getOrCreateFolder(
    drive.DriveApi driveApi,
    String folderName, {
    String? parentId,
  }) async {
    try {
      var query =
          "mimeType = 'application/vnd.google-apps.folder' and name = '$folderName' and trashed = false";
      if (parentId != null) {
        query += " and '$parentId' in parents";
      }

      debugPrint(
        'GoogleDriveService: Searching folder "$folderName" (parentId: $parentId)...',
      );
      final list = await driveApi.files.list(
        q: query,
        $fields: 'files(id, name, parents)',
      );

      if (list.files != null && list.files!.isNotEmpty) {
        final existingId = list.files!.first.id;
        debugPrint(
          'GoogleDriveService: Found existing folder "$folderName" -> $existingId',
        );
        return existingId;
      }

      debugPrint(
        'GoogleDriveService: Folder "$folderName" not found. Creating new folder...',
      );
      final folderToCreate = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = parentId != null ? [parentId] : null;

      final created = await driveApi.files.create(
        folderToCreate,
        $fields: 'id, name, mimeType, parents',
      );
      debugPrint(
        'GoogleDriveService: Successfully created folder "$folderName" -> ${created.id}',
      );
      return created.id;
    } catch (e, stack) {
      if (e.toString().contains('Google Drive API has not been used') ||
          e.toString().contains('disabled')) {
        lastErrorMessage =
            'Google Drive API is disabled in your Google Cloud Project (506029706494).\n\nPlease enable it at:\nhttps://console.developers.google.com/apis/api/drive.googleapis.com/overview?project=506029706494';
      } else {
        lastErrorMessage = e.toString();
      }
      debugPrint(
        'GoogleDriveService _getOrCreateFolder ERROR for "$folderName": $e\n$stack',
      );
      return null;
    }
  }

  /// Upload a File object into a specified Drive folder ID.
  static Future<String?> _uploadFileToFolder(
    drive.DriveApi driveApi,
    File file,
    String folderId, {
    String? customFileName,
  }) async {
    try {
      final fileName =
          customFileName ??
          'media_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last.split('\\').last}';

      debugPrint(
        'GoogleDriveService: Uploading "${file.path}" as "$fileName" into folderId: $folderId',
      );
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), file.lengthSync());
      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, webViewLink, webContentLink',
      );

      debugPrint(
        'GoogleDriveService: Uploaded file "$fileName" -> ${uploadedFile.id}',
      );

      if (uploadedFile.id != null) {
        return 'https://drive.google.com/uc?id=${uploadedFile.id}';
      }
      return null;
    } catch (e, stack) {
      debugPrint(
        'GoogleDriveService _uploadFileToFolder ERROR for "${file.path}": $e\n$stack',
      );
      return null;
    }
  }

  /// Upload a single image file for a pet into either 'profile_pet_picture' or 'pet_memories' subfolders.
  static Future<String?> uploadPetImageToDrive(
    File file,
    Pet pet, {
    required bool isProfilePicture,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        debugPrint(
          'GoogleDriveService uploadPetImageToDrive: driveApi is null',
        );
        return null;
      }

      final rootFolderId = await _getOrCreateFolder(driveApi, _rootFolderName);
      if (rootFolderId == null) return null;

      final petFolderName = pet.name.isNotEmpty ? pet.name : 'Unnamed_Pet';
      final petFolderId = await _getOrCreateFolder(
        driveApi,
        petFolderName,
        parentId: rootFolderId,
      );
      if (petFolderId == null) return null;

      final targetSubfolderName = isProfilePicture
          ? 'profile_pet_picture'
          : 'pet_memories';
      final subfolderId = await _getOrCreateFolder(
        driveApi,
        targetSubfolderName,
        parentId: petFolderId,
      );
      if (subfolderId == null) return null;

      return await _uploadFileToFolder(driveApi, file, subfolderId);
    } catch (e, stack) {
      debugPrint('GoogleDriveService uploadPetImageToDrive ERROR: $e\n$stack');
      return null;
    }
  }

  /// Syncs a Pet's profile picture (if not an asset avatar) and memory pictures to Google Drive.
  /// Structure created in Google Drive:
  /// PawsNCare_Media/
  ///   └── [Pet Name]/
  ///       ├── profile_pet_picture/
  ///       └── pet_memories/
  /// Returns updated Pet object with Google Drive URLs.
  static Future<Pet> syncPetToDrive(Pet pet) async {
    try {
      debugPrint('GoogleDriveService: Starting sync for pet "${pet.name}"...');
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        debugPrint('GoogleDriveService syncPetToDrive: driveApi is null');
        return pet;
      }

      final rootFolderId = await _getOrCreateFolder(driveApi, _rootFolderName);
      if (rootFolderId == null) return pet;

      final petFolderName = pet.name.isNotEmpty ? pet.name : 'Unnamed_Pet';
      final petFolderId = await _getOrCreateFolder(
        driveApi,
        petFolderName,
        parentId: rootFolderId,
      );
      if (petFolderId == null) return pet;

      final profileFolderId = await _getOrCreateFolder(
        driveApi,
        'profile_pet_picture',
        parentId: petFolderId,
      );
      final memoriesFolderId = await _getOrCreateFolder(
        driveApi,
        'pet_memories',
        parentId: petFolderId,
      );

      String updatedAvatarUrl = pet.avatarUrl;

      // 1. Sync Profile Picture (ONLY if NOT an asset avatar like 'assets/avatars/...')
      if (pet.avatarUrl.isNotEmpty &&
          !pet.avatarUrl.startsWith('assets/') &&
          !pet.avatarUrl.startsWith('http://') &&
          !pet.avatarUrl.startsWith('https://')) {
        final profileFile = File(pet.avatarUrl);
        if (profileFile.existsSync() && profileFolderId != null) {
          final driveUrl = await _uploadFileToFolder(
            driveApi,
            profileFile,
            profileFolderId,
            customFileName:
                '${pet.name}_profile_${profileFile.path.split('/').last.split('\\').last}',
          );
          if (driveUrl != null) {
            debugPrint('GoogleDriveService: Uploaded profile picture to Drive -> $driveUrl');
          }
        } else {
          debugPrint(
            'GoogleDriveService: Avatar file does not exist locally at "${pet.avatarUrl}"',
          );
        }
      }

      // 2. Sync Pet Memories / Album Photos
      final List<String> updatedPhotos = [];
      for (final photoPath in pet.photos) {
        if (photoPath.startsWith('assets/') ||
            photoPath.startsWith('http://') ||
            photoPath.startsWith('https://')) {
          updatedPhotos.add(photoPath);
          continue;
        }

        final photoFile = File(photoPath);
        if (photoFile.existsSync() && memoriesFolderId != null) {
          final driveUrl = await _uploadFileToFolder(
            driveApi,
            photoFile,
            memoriesFolderId,
          );
          if (driveUrl != null) {
            debugPrint('GoogleDriveService: Uploaded photo memory to Drive -> $driveUrl');
          }
          updatedPhotos.add(photoPath);
        } else {
          updatedPhotos.add(photoPath);
        }
      }

      debugPrint(
        'GoogleDriveService: Finished sync for pet "${pet.name}". Avatar: $updatedAvatarUrl',
      );
      return pet.copyWith(avatarUrl: updatedAvatarUrl, photos: updatedPhotos);
    } catch (e, stack) {
      debugPrint('GoogleDriveService syncPetToDrive ERROR: $e\n$stack');
      return pet;
    }
  }

  /// Syncs all registered pets' media to Google Drive, returning the list of updated Pet objects.
  static Future<List<Pet>> syncAllPetsToDrive(List<Pet> pets) async {
    debugPrint(
      'GoogleDriveService: Starting syncAllPetsToDrive for ${pets.length} pets...',
    );
    final List<Pet> updatedPets = [];
    for (final pet in pets) {
      final syncedPet = await syncPetToDrive(pet);
      updatedPets.add(syncedPet);
    }
    debugPrint('GoogleDriveService: Completed syncAllPetsToDrive.');
    return updatedPets;
  }

  /// Legacy single file upload fallback.
  static Future<String?> uploadImageToDrive(File file) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final rootFolderId = await _getOrCreateFolder(driveApi, _rootFolderName);
      if (rootFolderId == null) return null;

      return await _uploadFileToFolder(driveApi, file, rootFolderId);
    } catch (e) {
      return null;
    }
  }
}
