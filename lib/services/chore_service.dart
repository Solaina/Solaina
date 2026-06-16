import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chore.dart';

class ChoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String householdId) {
    return _db.collection('households').doc(householdId).collection('chores');
  }

  Future<void> addChore({
    required String householdId,
    required String title,
    required String assignedTo,
    required ChoreFrequency frequency,
    DateTime? dueDate,
  }) {
    return _collection(householdId).add(
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
    return _collection(householdId).doc(choreId).update({
      'completed': completed,
      'lastCompletedAt': completed ? Timestamp.now() : null,
    });
  }

  Future<void> deleteChore(String householdId, String choreId) {
    return _collection(householdId).doc(choreId).delete();
  }

  Stream<List<Chore>> watchChores(String householdId) {
    return _collection(householdId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Chore.fromMap(d.id, d.data())).toList(),
        );
  }
}
