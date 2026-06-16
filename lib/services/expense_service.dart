import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import 'app_mode.dart';
import 'local_store.dart';

class ExpenseService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String householdId) {
    return _db.collection('households').doc(householdId).collection('expenses');
  }

  Future<void> addExpense({
    required String householdId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> splitAmong,
  }) async {
    if (AppMode.useLocal) {
      await LocalStore.instance.addToCollection('expenses', householdId, {
        'description': description,
        'amount': amount,
        'paidBy': paidBy,
        'splitAmong': splitAmong,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'settled': false,
      });
      return;
    }
    await _collection(householdId).add(
      Expense(
        id: '',
        description: description,
        amount: amount,
        paidBy: paidBy,
        splitAmong: splitAmong,
        createdAt: DateTime.now(),
        settled: false,
      ).toMap(),
    );
  }

  Future<void> setSettled(String householdId, String expenseId, bool settled) {
    if (AppMode.useLocal) {
      return LocalStore.instance.updateInCollection(
        'expenses',
        householdId,
        expenseId,
        {'settled': settled},
      );
    }
    return _collection(householdId).doc(expenseId).update({'settled': settled});
  }

  Future<void> deleteExpense(String householdId, String expenseId) {
    if (AppMode.useLocal) {
      return LocalStore.instance.deleteFromCollection(
        'expenses',
        householdId,
        expenseId,
      );
    }
    return _collection(householdId).doc(expenseId).delete();
  }

  Stream<List<Expense>> watchExpenses(String householdId) {
    if (AppMode.useLocal) {
      return LocalStore.instance.watchCollection('expenses', householdId).map(
        (items) {
          final expenses = items
              .map(
                (raw) => Expense.fromMap(
                  raw['id'] as String,
                  LocalStore.withTimestamps(raw, ['createdAt']),
                ),
              )
              .toList();
          expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return expenses;
        },
      );
    }
    return _collection(householdId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Expense.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Returns net balance per member: positive means others owe them money,
  /// negative means they owe others, based on unsettled expenses.
  static Map<String, double> calculateBalances(
    List<Expense> expenses,
    List<String> memberIds,
  ) {
    final balances = {for (final id in memberIds) id: 0.0};
    for (final expense in expenses) {
      if (expense.settled) continue;
      final share = expense.shareAmount;
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;
      for (final memberId in expense.splitAmong) {
        balances[memberId] = (balances[memberId] ?? 0) - share;
      }
    }
    return balances;
  }
}
