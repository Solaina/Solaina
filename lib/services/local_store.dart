import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A device-only stand-in for Firebase Auth + Firestore, used when no real
/// Firebase project has been configured. Data is persisted as JSON in
/// SharedPreferences and does not sync between devices.
class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();

  static const _prefsKey = 'solaina_local_db_v1';
  static const _uuid = Uuid();

  late SharedPreferences _prefs;
  late Map<String, dynamic> _data;
  final _changes = StreamController<void>.broadcast();
  final _authChanges = StreamController<String?>.broadcast();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_prefsKey);
    _data = raw != null
        ? jsonDecode(raw) as Map<String, dynamic>
        : {
            'currentUserId': null,
            'users': <String, dynamic>{},
            'households': <String, dynamic>{},
            'members': <String, dynamic>{},
            'expenses': <String, dynamic>{},
            'groceryItems': <String, dynamic>{},
            'chores': <String, dynamic>{},
          };
  }

  Future<void> _persist() async {
    await _prefs.setString(_prefsKey, jsonEncode(_data));
    _changes.add(null);
  }

  Map<String, dynamic> _bucket(String name) =>
      _data[name] as Map<String, dynamic>;

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  /// Converts millisecond-epoch ints stored for [fields] back into Firestore
  /// `Timestamp` objects so the existing `Model.fromMap` constructors (which
  /// expect `Timestamp`) work unchanged in local mode.
  static Map<String, dynamic> withTimestamps(
    Map<String, dynamic> raw,
    List<String> fields,
  ) {
    final result = Map<String, dynamic>.from(raw);
    for (final field in fields) {
      final value = result[field];
      if (value is int) {
        result[field] = Timestamp.fromMillisecondsSinceEpoch(value);
      }
    }
    return result;
  }

  // ---- Auth ----

  String? get currentUserId => _data['currentUserId'] as String?;

  Stream<String?> get authStateChanges {
    return Stream<String?>.multi((controller) {
      controller.add(currentUserId);
      final sub = _authChanges.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final users = _bucket('users');
    final normalizedEmail = email.trim().toLowerCase();
    final exists = users.values.any(
      (u) => (u as Map)['email'] == normalizedEmail,
    );
    if (exists) {
      throw Exception('An account with that email already exists.');
    }
    final uid = _uuid.v4();
    users[uid] = {
      'email': normalizedEmail,
      'passwordHash': _hashPassword(password),
      'displayName': displayName,
      'householdId': null,
    };
    _data['currentUserId'] = uid;
    await _persist();
    _authChanges.add(uid);
  }

  Future<void> signIn({required String email, required String password}) async {
    final users = _bucket('users');
    final normalizedEmail = email.trim().toLowerCase();
    final hash = _hashPassword(password);
    MapEntry<String, dynamic>? match;
    for (final entry in users.entries) {
      final user = entry.value as Map;
      if (user['email'] == normalizedEmail && user['passwordHash'] == hash) {
        match = entry;
        break;
      }
    }
    if (match == null) {
      throw Exception('Invalid email or password.');
    }
    _data['currentUserId'] = match.key;
    await _persist();
    _authChanges.add(match.key);
  }

  Future<void> signOut() async {
    _data['currentUserId'] = null;
    await _persist();
    _authChanges.add(null);
  }

  Stream<Map<String, dynamic>?> watchUser(String userId) {
    return Stream<Map<String, dynamic>?>.multi((controller) {
      void emit() {
        final user = _bucket('users')[userId] as Map<String, dynamic>?;
        controller.add(user == null ? null : Map<String, dynamic>.from(user));
      }

      emit();
      final sub = _changes.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    });
  }

  Future<void> setHouseholdId(String userId, String? householdId) async {
    (_bucket('users')[userId] as Map<String, dynamic>)['householdId'] =
        householdId;
    await _persist();
  }

  // ---- Households ----

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
    final id = _uuid.v4();
    _bucket('households')[id] = {
      'name': name,
      'inviteCode': _generateInviteCode(),
      'memberIds': [userId],
    };
    _bucket('members')[id] = {
      userId: {'displayName': displayName},
    };
    await _persist();
    return id;
  }

  Future<String> joinHousehold({
    required String inviteCode,
    required String userId,
    required String displayName,
  }) async {
    final households = _bucket('households');
    MapEntry<String, dynamic>? match;
    for (final entry in households.entries) {
      if ((entry.value as Map)['inviteCode'] == inviteCode.toUpperCase()) {
        match = entry;
        break;
      }
    }
    if (match == null) {
      throw Exception('No household found with that invite code.');
    }
    final household = match.value as Map<String, dynamic>;
    final memberIds = List<String>.from(household['memberIds'] as List);
    if (!memberIds.contains(userId)) memberIds.add(userId);
    household['memberIds'] = memberIds;
    final members =
        _bucket('members').putIfAbsent(match.key, () => <String, dynamic>{})
            as Map<String, dynamic>;
    members[userId] = {'displayName': displayName};
    await _persist();
    return match.key;
  }

  Stream<Map<String, dynamic>?> watchHousehold(String householdId) {
    return Stream<Map<String, dynamic>?>.multi((controller) {
      void emit() {
        final household =
            _bucket('households')[householdId] as Map<String, dynamic>?;
        controller.add(
          household == null ? null : Map<String, dynamic>.from(household),
        );
      }

      emit();
      final sub = _changes.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    });
  }

  Stream<List<Map<String, dynamic>>> watchMembers(String householdId) {
    return Stream<List<Map<String, dynamic>>>.multi((controller) {
      void emit() {
        final members =
            _bucket('members')[householdId] as Map<String, dynamic>? ?? {};
        controller.add(
          members.entries
              .map(
                (e) => {'id': e.key, ...(e.value as Map<String, dynamic>)},
              )
              .toList(),
        );
      }

      emit();
      final sub = _changes.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    });
  }

  // ---- Generic per-household collections (expenses / groceryItems / chores) ----

  Future<String> addToCollection(
    String collection,
    String householdId,
    Map<String, dynamic> data,
  ) async {
    final id = _uuid.v4();
    final bucket =
        _bucket(collection).putIfAbsent(householdId, () => <String, dynamic>{})
            as Map<String, dynamic>;
    bucket[id] = data;
    await _persist();
    return id;
  }

  Future<void> updateInCollection(
    String collection,
    String householdId,
    String id,
    Map<String, dynamic> updates,
  ) async {
    final bucket = _bucket(collection)[householdId] as Map<String, dynamic>?;
    final item = bucket?[id] as Map<String, dynamic>?;
    item?.addAll(updates);
    await _persist();
  }

  Future<void> deleteFromCollection(
    String collection,
    String householdId,
    String id,
  ) async {
    final bucket = _bucket(collection)[householdId] as Map<String, dynamic>?;
    bucket?.remove(id);
    await _persist();
  }

  Stream<List<Map<String, dynamic>>> watchCollection(
    String collection,
    String householdId,
  ) {
    return Stream<List<Map<String, dynamic>>>.multi((controller) {
      void emit() {
        final bucket =
            _bucket(collection)[householdId] as Map<String, dynamic>? ?? {};
        controller.add(
          bucket.entries
              .map(
                (e) => {
                  'id': e.key,
                  ...Map<String, dynamic>.from(e.value as Map),
                },
              )
              .toList(),
        );
      }

      emit();
      final sub = _changes.stream.listen((_) => emit());
      controller.onCancel = sub.cancel;
    });
  }
}
