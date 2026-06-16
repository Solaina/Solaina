import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/household.dart';
import 'app_mode.dart';
import 'local_store.dart';

class HouseholdService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> createHousehold({
    required String name,
    required String userId,
    required String displayName,
  }) async {
    if (AppMode.useLocal) {
      return LocalStore.instance.createHousehold(
        name: name,
        userId: userId,
        displayName: displayName,
      );
    }
    final docRef = _db.collection('households').doc();
    await docRef.set(
      Household(
        id: docRef.id,
        name: name,
        inviteCode: _generateInviteCode(),
        memberIds: [userId],
      ).toMap(),
    );
    await docRef
        .collection('members')
        .doc(userId)
        .set(HouseholdMember(userId: userId, displayName: displayName).toMap());
    return docRef.id;
  }

  Future<String> joinHousehold({
    required String inviteCode,
    required String userId,
    required String displayName,
  }) async {
    if (AppMode.useLocal) {
      return LocalStore.instance.joinHousehold(
        inviteCode: inviteCode,
        userId: userId,
        displayName: displayName,
      );
    }
    final query = await _db
        .collection('households')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception('No household found with that invite code.');
    }
    final doc = query.docs.first;
    await doc.reference.update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    await doc.reference
        .collection('members')
        .doc(userId)
        .set(HouseholdMember(userId: userId, displayName: displayName).toMap());
    return doc.id;
  }

  Stream<Household> watchHousehold(String householdId) {
    if (AppMode.useLocal) {
      return LocalStore.instance
          .watchHousehold(householdId)
          .where((data) => data != null)
          .map((data) => Household.fromMap(householdId, data!));
    }
    return _db
        .collection('households')
        .doc(householdId)
        .snapshots()
        .map((snap) => Household.fromMap(snap.id, snap.data()!));
  }

  Stream<List<HouseholdMember>> watchMembers(String householdId) {
    if (AppMode.useLocal) {
      return LocalStore.instance.watchMembers(householdId).map(
        (members) => members
            .map((m) => HouseholdMember.fromMap(m['id'] as String, m))
            .toList(),
      );
    }
    return _db
        .collection('households')
        .doc(householdId)
        .collection('members')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => HouseholdMember.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
