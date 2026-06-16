import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chore.dart';
import 'app_mode.dart';
import 'local_store.dart';

class ChoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String householdId) {
    return _db.collection('households').doc(householdId).collection('chores');
  }

  Future<void> addChore({
    required String householdId,
    required String title,
    required String assignedTo,
    required ChoreFrequency frequency,
    DateTime? dueDate,
  }) async {
    if (AppMode.useLocal) {
      await LocalStore.instance.addToCollection('chores', householdId, {
        'title': title,
        'assignedTo': assignedTo,
        'frequency': frequency.name,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'completed': false,
        'lastCompletedAt': null,
      });
      return;
    }
    await _collection(householdId).add(
      Chore(
        id: '',
        title: title,
        assignedTo: assignedTo,
        frequency: frequency,
        dueDate: dueDate,
        completed: false,
        lastCompletedAt: null,
      ).toMap(),
    );
  }

  Future<void> setCompleted(
    String householdId,
    String choreId,
    bool completed,
  ) {
    if (AppMode.useLocal) {
      return LocalStore.instance.updateInCollection(
        'chores',
        householdId,
        choreId,
        {
          'completed': completed,
          'lastCompletedAt': completed
              ? DateTime.now().millisecondsSinceEpoch
              : null,
        },
      );
    }
    return _collection(householdId).doc(choreId).update({
      'completed': completed,
      'lastCompletedAt': completed ? Timestamp.now() : null,
    });
  }

  Future<void> deleteChore(String householdId, String choreId) {
    if (AppMode.useLocal) {
      return LocalStore.instance.deleteFromCollection(
        'chores',
        householdId,
        choreId,
      );
    }
    return _collection(householdId).doc(choreId).delete();
  }

  Stream<List<Chore>> watchChores(String householdId) {
    if (AppMode.useLocal) {
      return LocalStore.instance.watchCollection('chores', householdId).map((
        items,
      ) {
        final chores = items
            .map(
              (raw) => Chore.fromMap(
                raw['id'] as String,
                LocalStore.withTimestamps(raw, ['dueDate', 'lastCompletedAt']),
              ),
            )
            .toList();
        chores.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        return chores;
      });
    }
    return _collection(householdId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Chore.fromMap(d.id, d.data())).toList(),
        );
  }
}
