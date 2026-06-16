import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'app_mode.dart';
import 'local_store.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Stream<String?> get authStateChanges {
    if (AppMode.useLocal) return LocalStore.instance.authStateChanges;
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  String? get currentUserId {
    if (AppMode.useLocal) return LocalStore.instance.currentUserId;
    return _auth.currentUser?.uid;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (AppMode.useLocal) {
      return LocalStore.instance.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    await _db
        .collection('users')
        .doc(user.uid)
        .set(
          AppUser(id: user.uid, displayName: displayName, email: email).toMap(),
        );
  }

  Future<void> signIn({required String email, required String password}) {
    if (AppMode.useLocal) {
      return LocalStore.instance.signIn(email: email, password: password);
    }
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() {
    if (AppMode.useLocal) return LocalStore.instance.signOut();
    return _auth.signOut();
  }

  Stream<AppUser?> watchAppUser(String userId) {
    if (AppMode.useLocal) {
      return LocalStore.instance
          .watchUser(userId)
          .map((data) => data == null ? null : AppUser.fromMap(userId, data));
    }
    return _db.collection('users').doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(snap.id, snap.data()!);
    });
  }

  Future<void> setHouseholdId(String userId, String? householdId) {
    if (AppMode.useLocal) {
      return LocalStore.instance.setHouseholdId(userId, householdId);
    }
    return _db.collection('users').doc(userId).update({
      'householdId': householdId,
    });
  }
}
