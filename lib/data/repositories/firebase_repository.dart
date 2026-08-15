import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../models/diary_entry.dart';
import 'base_repository.dart';

class FirebaseRepository implements BaseRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _petsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('pets');
  }

  CollectionReference<Map<String, dynamic>>? get _diaryRef {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('diary');
  }

  // --- Auth Operations ---
  @override
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<bool> register(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        // Initialize user document in firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    return _auth.currentUser?.email;
  }

  @override
  Future<String?> getCurrentUserName() async {
    return _auth.currentUser?.displayName;
  }

  // --- Pet Operations ---
  @override
  Future<List<Pet>> getPets() async {
    final ref = _petsRef;
    if (ref == null) return [];
    final snapshot = await ref.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Pet.fromMap(data);
    }).toList();
  }

  @override
  Future<void> addPet(Pet pet) async {
    final ref = _petsRef;
    if (ref == null) throw Exception("User not authenticated");
    final data = pet.toMap();
    data.remove('id'); // Firestore generates the ID
    await ref.doc(pet.id.isEmpty ? null : pet.id).set(data);
  }

  @override
  Future<void> updatePet(Pet pet) async {
    final ref = _petsRef;
    if (ref == null) throw Exception("User not authenticated");
    await ref.doc(pet.id).update(pet.toMap());
  }

  @override
  Future<void> deletePet(String petId) async {
    final ref = _petsRef;
    if (ref == null) throw Exception("User not authenticated");
    await ref.doc(petId).delete();
    
    // Also delete diary entries belonging to this pet
    final dRef = _diaryRef;
    if (dRef != null) {
      final diarySnapshot = await dRef.where('petId', isEqualTo: petId).get();
      final batch = _firestore.batch();
      for (var doc in diarySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // --- Diary Operations ---
  @override
  Future<List<DiaryEntry>> getDiaryEntries(String petId) async {
    final ref = _diaryRef;
    if (ref == null) return [];
    final snapshot = await ref.where('petId', isEqualTo: petId).get();
    final entries = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return DiaryEntry.fromMap(data);
    }).toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  @override
  Future<List<DiaryEntry>> getAllDiaryEntries() async {
    final ref = _diaryRef;
    if (ref == null) return [];
    final snapshot = await ref.get();
    final entries = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return DiaryEntry.fromMap(data);
    }).toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  @override
  Future<void> addDiaryEntry(DiaryEntry entry) async {
    final ref = _diaryRef;
    if (ref == null) throw Exception("User not authenticated");
    final data = entry.toMap();
    data.remove('id'); // Firestore generates the ID
    await ref.add(data);
  }
}
