import '../models/pet.dart';
import '../models/diary_entry.dart';

abstract class BaseRepository {
  // Auth Operations
  Future<bool> login(String email, String password);
  Future<bool> loginWithGoogle();
  Future<bool> register(String email, String password, String name);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String?> getCurrentUserEmail();
  Future<String?> getCurrentUserName();
  Future<void> updateUserName(String newName);
  Future<void> sendEmailVerification();
  Future<void> sendPasswordResetEmail(String email);

  // Pet Operations
  Future<List<Pet>> getPets();
  Future<void> addPet(Pet pet);
  Future<void> updatePet(Pet pet);
  Future<void> deletePet(String petId);

  // Diary Operations
  Future<List<DiaryEntry>> getDiaryEntries(String petId);
  Future<List<DiaryEntry>> getAllDiaryEntries();
  Future<void> addDiaryEntry(DiaryEntry entry);
  Future<void> deleteDiaryEntry(String entryId);
}
