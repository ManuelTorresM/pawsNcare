import 'dart:io';
import 'base_repository.dart';
import '../models/pet.dart';
import '../models/diary_entry.dart';
import '../demo/demo_data_supplier.dart';

class DemoRepository implements BaseRepository {
  final List<Pet> _demoPets = List.from(DemoDataSupplier.demoPets);
  final List<DiaryEntry> _demoEntries = [];

  final Set<String> _registeredEmails = {'demo@pawsncare.com'};

  @override
  Future<String?> uploadImage(File file, String storagePath) async => file.path;

  @override
  Future<bool> login(String email, String password) async {
    final clean = email.trim().toLowerCase();
    if (!_registeredEmails.contains(clean)) {
      throw Exception(
        'No account found for "$email". Please sign up first before logging in.',
      );
    }
    return true;
  }

  @override
  Future<bool> loginWithGoogle() async {
    if (!_registeredEmails.contains('google_demo@pawsncare.com')) {
      throw Exception(
        'No registered account found for this Google email. Please sign up first!',
      );
    }
    return true;
  }

  @override
  Future<bool> register(String email, String password, String name) async {
    _registeredEmails.add(email.trim().toLowerCase());
    return true;
  }

  @override
  Future<bool> registerWithGoogle() async {
    _registeredEmails.add('demo@pawsncare.com');
    return true;
  }

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
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    final idx = _demoEntries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _demoEntries[idx] = entry;
    } else {
      _demoEntries.add(entry);
    }
  }

  @override
  Future<void> deleteDiaryEntry(String entryId) async {
    _demoEntries.removeWhere((e) => e.id == entryId);
  }
}
