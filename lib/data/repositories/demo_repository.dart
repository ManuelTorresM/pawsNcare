import 'dart:io';
import 'base_repository.dart';
import '../models/pet.dart';
import '../models/diary_entry.dart';
import '../demo/demo_data_supplier.dart';

class DemoRepository implements BaseRepository {
  final List<Pet> _demoPets = List.from(DemoDataSupplier.demoPets);
  final List<DiaryEntry> _demoEntries = [];

  @override
  Future<String?> uploadImage(File file, String storagePath) async => file.path;

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<bool> loginWithGoogle() async => true;

  @override
  Future<bool> register(String email, String password, String name) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<String?> getCurrentUserEmail() async => 'demo@pawsncare.com';

  @override
  Future<String?> getCurrentUserName() async => 'Demo User';

  @override
  Future<void> updateUserName(String newName) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<List<Pet>> getPets() async => List.from(_demoPets);

  @override
  Future<void> addPet(Pet pet) async {
    _demoPets.add(pet);
  }

  @override
  Future<void> updatePet(Pet pet) async {
    final index = _demoPets.indexWhere((p) => p.id == pet.id);
    if (index != -1) {
      _demoPets[index] = pet;
    }
  }

  @override
  Future<void> deletePet(String petId) async {
    _demoPets.removeWhere((p) => p.id == petId);
  }

  @override
  Future<List<DiaryEntry>> getDiaryEntries(String petId) async {
    return _demoEntries.where((e) => e.petId == petId).toList();
  }

  @override
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    return List.from(_demoEntries);
  }

  @override
  Future<void> addDiaryEntry(DiaryEntry entry) async {
    _demoEntries.add(entry);
  }

  @override
  Future<void> deleteDiaryEntry(String entryId) async {
    _demoEntries.removeWhere((e) => e.id == entryId);
  }
}
