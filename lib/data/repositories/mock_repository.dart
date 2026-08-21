import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/diary_entry.dart';
import '../models/weight_log.dart';
import '../models/medication.dart';
import 'base_repository.dart';

class MockRepository implements BaseRepository {
  static const String _petsKey = 'pawsncare_mock_pets';
  static const String _diaryKey = 'pawsncare_mock_diary';
  static const String _userKey = 'pawsncare_mock_user';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  List<Pet> _pets = [];
  List<DiaryEntry> _diaryEntries = [];
  Map<String, String>? _currentUser;

  MockRepository() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load User
    final userJson = _prefs.getString(_userKey);
    if (userJson != null) {
      _currentUser = Map<String, String>.from(json.decode(userJson));
    }

    // Load Pets
    final petsJson = _prefs.getString(_petsKey);
    if (petsJson != null) {
      final List decoded = json.decode(petsJson);
      _pets = decoded.map((x) => Pet.fromMap(x)).toList();
    } else {
      _loadDefaultPets();
    }

    // Load Diary
    final diaryJson = _prefs.getString(_diaryKey);
    if (diaryJson != null) {
      final List decoded = json.decode(diaryJson);
      _diaryEntries = decoded.map((x) => DiaryEntry.fromMap(x)).toList();
    } else {
      _loadDefaultDiary();
    }

    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _init();
    }
  }

  void _loadDefaultPets() {
    _pets = [
      Pet(
        id: 'luna',
        name: 'Luna',
        breed: 'Golden Retriever',
        ageString: '3y 4m',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 3 + 120)),
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH4q1ZxA4-kVWnFA2l_v138H6omdsv0f2VnRf02r4qUhGIC31Q7V-6LJi9vOTHwCzivv5LXVUp0uqEgLAwY5VAR_upvrgz6VicZcLd64Mp0aXTBK2roz-VVty2zgv4wRykLUcXIDql4wM8lzVEza8ZPVfiOO5cKGHFaHOFWzO1mcbgd5aBQ1NIhs0njlmtX_bce3QhiwKizYSRoyX23nCmNgQSIzzPBJa94FxPhSZvNg3ZDpX2SX7AY9us3VFc3LTeFryokjTdEL8',
        status: 'Healthy',
        weight: 28.5,
        weightHistory: [
          WeightLog(id: 'w1', weight: 28.5, date: DateTime.now().subtract(const Duration(days: 5)), note: 'At Home'),
          WeightLog(id: 'w2', weight: 28.2, date: DateTime.now().subtract(const Duration(days: 30)), note: 'Vet Visit'),
          WeightLog(id: 'w3', weight: 28.8, date: DateTime.now().subtract(const Duration(days: 60)), note: 'At Home'),
          WeightLog(id: 'w4', weight: 27.5, date: DateTime.now().subtract(const Duration(days: 90)), note: 'At Home'),
          WeightLog(id: 'w5', weight: 27.1, date: DateTime.now().subtract(const Duration(days: 120)), note: 'At Home'),
        ],
        medications: [
          Medication(id: 'm1', name: 'Flea & Tick Prevention', nextDoseDate: DateTime.now().add(const Duration(days: 15)), administeredDate: DateTime.now().subtract(const Duration(days: 15)), isCompleted: true, type: 'flea_tick'),
          Medication(id: 'm2', name: 'Heartworm Medication', nextDoseDate: DateTime.now().add(const Duration(days: 20)), administeredDate: DateTime.now().subtract(const Duration(days: 10)), isCompleted: true, type: 'heartworm'),
        ],
        photos: const [
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBl6_oeyQV-qIsHy9D2xNcPoSyI7ccxSlfqGkCntb0EHHM0IW8i2DJJ_EL50ABz-nrZGOve9I94OWfLqfeoUVb8n4f9bA9AQ5OXZGBcCJc4BXtF1nUjbT3E48dDGWmqR2iXZa6zZwoocYCfKmZuUE62NNnvl9RsY8V0NW3q3IbTRAQHgwKjPgwgnVBd18QplOa5vj6TTXbI1hoa-mXfjtWubK9aEzqQm8gp7bxm6d05ICVbPtB5r1p5',
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDud1dBMCEUUnS8K3QpiIJN5zyzK6QNXJHb9CTg5iZjYfeN62Drez_cUi63k0F1v0zuQFz3nSdSjlVztVPWHw03FTgM7Wxd9fmApweagP0Ec3sILeqiuparq7xX2EW_3xY83Y4Y_tl727B4VJB3QEC9XIa2cRvKY7jDfuegGj-jiCx25aOloIZE3_kc7kuZX-V09dvFFpADHI5NMUfsrCYDMebDNdBzZpz5NDAvSEJRU0LfDaMg_c5L',
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDDw84DnYLoEJSpFWlKDWSCNGtehkk_-Rkw1bRnIkjwAuOdzzqFh1LTwZdLPa9rD7iPsmAeMXIkN_iJQLb8PiLJnXIOfFRyC5DOEHkv5ZAy9wPNPkOsgHORtRlXvdTkzYA9HxAZJ0O3X9LubybYLSCDGBJxReMv5WmHcZZk4C86lIcpQgMlpKpG3z5ggne_6dKyxUprFLBP_lq8FXNJUyaoMCBf3CIfdzitQIcpyTyKdlYQxeiXkkmh',
        ],
        species: 'Dog',
        gender: 'Female',
        neutered: 'Yes',
        allergies: const ['Chicken', 'Grain'],
        activityLevel: 'Moderate',
        dietEnabled: true,
        foodType: 'Dry Kibble',
        feedingNotes: '2 cups/day',
        behaviorTags: const ['Social', 'Playful', 'Vocal'],
      ),
      Pet(
        id: 'oliver',
        name: 'Oliver',
        breed: 'Domestic Shorthair',
        ageString: '2y 1m',
        birthDate: DateTime.now().subtract(const Duration(days: 365 * 2 + 30)),
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCpT0s0cFYKkX1zUW-ZxppNCO4wIccsTDYvXkjapAsnMu64RzcaIUjAF0H_2Z_WImyF9vDl54Sd3UiP8Ze5UwJCBZhzY5FspotvD89AoJIuI5Inn5ez8rIlp1bz5pzc4VDZy3Mb3iWysaRQGcBlkvhzu4sWcYTdGUqckqvHPXeE6q24o_m3TOQk074Iz5uEfq4ENSFLNa4jiPJM30P2AZWfGFsGOCUbxziOc6wn0t_P1SBzdjxDxS1TjE4Wf6LRSbHHQaaCMa8GmRs',
        status: 'Check Diary',
        weight: 4.5,
        weightHistory: [
          WeightLog(id: 'w10', weight: 4.5, date: DateTime.now(), note: 'Weekly weigh-in'),
        ],
        medications: const [],
        photos: const [],
        species: 'Cat',
        gender: 'Male',
        neutered: 'Yes',
        allergies: const ['Dairy'],
        activityLevel: 'Mild',
        dietEnabled: true,
        foodType: 'Wet Food',
        feedingNotes: '1 can/day',
        behaviorTags: const ['Curious', 'Independent'],
      ),
      Pet(
        id: 'bella',
        name: 'Bella',
        breed: 'Beagle',
        ageString: '8m',
        birthDate: DateTime.now().subtract(const Duration(days: 240)),
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCFcNElyLf3r5PA_2Elk94qMT0TQ-23Cgjap0di5FfbqGolohXnnNV8egscRbhfJTjr8ps-_SniD5702oFSwCSOBM24tKV8qX9c6VhDNNrwVS3cdRvVJgDKxDKaVwT2HIga6UDbEa1syicPc-biHozPmapknaq-BNkvBnifXh2drwb6Vccjq7188kkO1r6VS-vhDfx_-O6fP-Jiyzbf4rUeWPYdnmLkGz4iQ4mgssMdKszHy_tIj9AcyPHqKmdt82FUEx28UYD0yFs',
        status: 'Puppy',
        weight: 9.2,
        weightHistory: [
          WeightLog(id: 'w20', weight: 9.2, date: DateTime.now(), note: 'Puppy growth log'),
        ],
        medications: const [],
        photos: const [],
        species: 'Dog',
        gender: 'Female',
        neutered: 'Yes',
        allergies: const [],
        activityLevel: 'High',
        dietEnabled: true,
        foodType: 'Puppy Kibble',
        feedingNotes: '3 times/day',
        behaviorTags: const ['Playful', 'Energetic', 'Social'],
      ),
    ];
    _savePets();
  }

  void _loadDefaultDiary() {
    _diaryEntries = [
      DiaryEntry(
        id: 'd1',
        petId: 'luna',
        title: 'Dinner: New Brand',
        category: 'food',
        note: 'Switched to Salmon & Sweet Potato. She finished the whole bowl in record time!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      DiaryEntry(
        id: 'd2',
        petId: 'luna',
        title: 'Morning Hike',
        category: 'walk',
        note: '45 min trail walk at Pine Crest. Very energetic, met two other dogs.',
        timestamp: DateTime.now().subtract(const Duration(hours: 10)),
      ),
      DiaryEntry(
        id: 'd3',
        petId: 'luna',
        title: 'Monthly Dewormer',
        category: 'med',
        note: 'Regular dose administered with dinner. No side effects noted.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DiaryEntry(
        id: 'd4',
        petId: 'oliver',
        title: 'Fever check',
        category: 'vet',
        note: 'Oliver seems a bit lethargic today. Logged to monitor his temperature.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
    _saveDiary();
  }

  Future<void> _savePets() async {
    final data = _pets.map((p) => p.toMap()).toList();
    await _prefs.setString(_petsKey, json.encode(data));
  }

  Future<void> _saveDiary() async {
    final data = _diaryEntries.map((d) => d.toMap()).toList();
    await _prefs.setString(_diaryKey, json.encode(data));
  }

  // --- Auth Repository Implementation ---
  @override
  Future<bool> login(String email, String password) async {
    await _ensureInitialized();
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = {
      'email': email,
      'name': email.split('@').first.toUpperCase(),
    };
    await _prefs.setString(_userKey, json.encode(_currentUser));
    return true;
  }

  @override
  Future<bool> loginWithGoogle() async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = {
      'email': 'google.user@example.com',
      'name': 'Google User',
    };
    await _prefs.setString(_userKey, json.encode(_currentUser));
    return true;
  }

  @override
  Future<bool> register(String email, String password, String name) async {
    await _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = {
      'email': email,
      'name': name,
    };
    await _prefs.setString(_userKey, json.encode(_currentUser));
    return true;
  }

  @override
  Future<void> logout() async {
    await _ensureInitialized();
    _currentUser = null;
    await _prefs.remove(_userKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    await _ensureInitialized();
    return _currentUser != null;
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    await _ensureInitialized();
    return _currentUser?['email'];
  }

  @override
  Future<String?> getCurrentUserName() async {
    await _ensureInitialized();
    return _currentUser?['name'] ?? 'Guest';
  }

  @override
  Future<void> updateUserName(String newName) async {
    await _ensureInitialized();
    if (_currentUser != null) {
      _currentUser!['name'] = newName;
      await _prefs.setString(_userKey, json.encode(_currentUser));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    // Mock simulation
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Mock simulation
  }

  // --- Pets Repository Implementation ---
  @override
  Future<List<Pet>> getPets() async {
    await _ensureInitialized();
    return _pets;
  }

  @override
  Future<void> addPet(Pet pet) async {
    await _ensureInitialized();
    _pets.add(pet);
    await _savePets();
  }

  @override
  Future<void> updatePet(Pet pet) async {
    await _ensureInitialized();
    final idx = _pets.indexWhere((p) => p.id == pet.id);
    if (idx != -1) {
      _pets[idx] = pet;
      await _savePets();
    }
  }

  @override
  Future<void> deletePet(String petId) async {
    await _ensureInitialized();
    _pets.removeWhere((p) => p.id == petId);
    _diaryEntries.removeWhere((d) => d.petId == petId);
    await _savePets();
    await _saveDiary();
  }

  // --- Diary Repository Implementation ---
  @override
  Future<List<DiaryEntry>> getDiaryEntries(String petId) async {
    await _ensureInitialized();
    final entries = _diaryEntries.where((d) => d.petId == petId).toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  @override
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    await _ensureInitialized();
    final entries = List<DiaryEntry>.from(_diaryEntries);
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  @override
  Future<void> addDiaryEntry(DiaryEntry entry) async {
    await _ensureInitialized();
    _diaryEntries.add(entry);
    await _saveDiary();
  }

  @override
  Future<void> deleteDiaryEntry(String entryId) async {
    await _ensureInitialized();
    _diaryEntries.removeWhere((d) => d.id == entryId);
    await _saveDiary();
  }
}
