import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/pet.dart';
import '../models/pet_invitation.dart';
import '../models/shared_member.dart';
import '../models/pet_role.dart';
import '../models/diary_entry.dart';
import 'base_repository.dart';

class FirebaseRepository implements BaseRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String?> uploadImage(File file, String storagePath) async => file.path;

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

  @override
  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      if (credential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();
        if (!userDoc.exists) {
          await _auth.signOut();
          throw Exception(
            'No account found for "$cleanEmail". Please sign up first before logging in.',
          );
        }
      }

      return true;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please verify your credentials.');
      }
      throw Exception(
        'No account found for "$cleanEmail". Please sign up first before logging in.',
      );
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password. Please verify your credentials.');
      }
      throw Exception(
        'No account found for "$cleanEmail". Please sign up first before logging in.',
      );
    }
  }

  @override
  Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          await _auth.signOut();
          await GoogleSignIn().signOut();
          throw Exception(
            'No registered account found for this Google email. Please sign up first!',
          );
        }
      }
      return true;
    } catch (_) {
      throw Exception(
        'No registered account found for this Google email. Please sign up first!',
      );
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
        try {
          await credential.user!.sendEmailVerification();
        } catch (_) {}
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
  Future<bool> registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Google User',
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
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

  @override
  Future<void> updateUserName(String newName) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(newName);
      await _firestore.collection('users').doc(user.uid).set({
        'name': newName,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- Pet Operations ---
  @override
  Future<List<Pet>> getPets() async {
    final uid = _uid;
    final email = _auth.currentUser?.email?.toLowerCase();
    if (uid == null) return [];

    final Map<String, Pet> petMap = {};

    // 1. Fetch user's own pets
    final ref = _petsRef;
    if (ref != null) {
      final snapshot = await ref.get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final pet = Pet.fromMap(data);
        petMap[pet.id] = pet;
      }
    }

    // 2. Fetch pets shared with user via collectionGroup
    try {
      final groupSnapshot = await _firestore.collectionGroup('pets').get();
      for (var doc in groupSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final pet = Pet.fromMap(data);

        final memberMatches = pet.members.where(
          (m) =>
              m.id == uid || (email != null && m.email.toLowerCase() == email),
        );

        if (memberMatches.isNotEmpty) {
          final member = memberMatches.first;
          // If invitation is Pending, only return sanitized minimal replica to prevent privacy leaks
          if (member.status == 'Pending') {
            petMap[pet.id] = pet.toPendingReplica();
          } else if (member.status == 'Active') {
            petMap[pet.id] = pet.toConsistentImageReplica(currentUserId: uid);
          }
        }
      }
    } catch (_) {
      // Fallback if index build in progress
    }

    return petMap.values.toList();
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
    final uid = _uid;
    if (uid == null) throw Exception("User not authenticated");

    final targetOwnerId = pet.ownerId.isNotEmpty ? pet.ownerId : uid;

    await _firestore
        .collection('users')
        .doc(targetOwnerId)
        .collection('pets')
        .doc(pet.id)
        .set(pet.toMap(), SetOptions(merge: true));
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

  // --- Invitation Operations ---
  Future<void> sendInvitation(PetInvitation invitation) async {
    // Write invitation to top-level invitations collection
    await _firestore
        .collection('invitations')
        .doc(invitation.id)
        .set(invitation.toMap(), SetOptions(merge: true));
  }

  Future<List<PetInvitation>> getPendingInvitationsForCurrentUser() async {
    final email = _auth.currentUser?.email?.toLowerCase();
    if (email == null || email.isEmpty) return [];

    try {
      final snapshot = await _firestore.collection('invitations').get();
      final list = <PetInvitation>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final inv = PetInvitation.fromMap(data);
        if (inv.status == 'Pending' &&
            inv.recipientEmail.toLowerCase() == email) {
          list.add(inv);
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> acceptInvitation(PetInvitation invitation) async {
    final uid = _uid;
    final email = _auth.currentUser?.email ?? invitation.recipientEmail;

    // 1. Update invitation status to Active
    await _firestore.collection('invitations').doc(invitation.id).update({
      'status': 'Active',
    });

    // 2. Add or update member in pet's document under owner's subcollection
    if (invitation.ownerId.isNotEmpty && invitation.petId.isNotEmpty) {
      final petDocRef = _firestore
          .collection('users')
          .doc(invitation.ownerId)
          .collection('pets')
          .doc(invitation.petId);

      final doc = await petDocRef.get();
      if (doc.exists && doc.data() != null) {
        final pet = Pet.fromMap(doc.data()!);
        final updatedMembers = List<SharedMember>.from(pet.members);

        final existingIdx = updatedMembers.indexWhere(
          (m) =>
              m.email.toLowerCase() == email.toLowerCase() ||
              (uid != null && m.id == uid),
        );

        final activeMember = SharedMember(
          id: uid ?? invitation.recipientEmail,
          email: email,
          name: invitation.recipientUsername.isNotEmpty
              ? invitation.recipientUsername
              : email.split('@').first,
          role: invitation.role,
          joinedAt: DateTime.now(),
          status: 'Active',
        );

        if (existingIdx >= 0) {
          updatedMembers[existingIdx] = activeMember;
        } else {
          updatedMembers.add(activeMember);
        }

        var updatedPet = pet.copyWith(members: updatedMembers);
        if (invitation.role == PetRole.owner && uid != null) {
          updatedPet = updatedPet.copyWith(ownerId: uid);
        }

        await petDocRef.set(updatedPet.toMap(), SetOptions(merge: true));
      }
    }
  }

  Future<void> declineInvitation(PetInvitation invitation) async {
    // Update invitation status to Declined
    await _firestore.collection('invitations').doc(invitation.id).update({
      'status': 'Declined',
    });
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

  @override
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    final ref = _diaryRef;
    if (ref == null) throw Exception("User not authenticated");
    final data = entry.toMap();
    await ref.doc(entry.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteDiaryEntry(String entryId) async {
    final ref = _diaryRef;
    if (ref == null) throw Exception("User not authenticated");
    await ref.doc(entryId).delete();
  }
}
