import 'package:flutter_test/flutter_test.dart';

import 'package:solaina/models/expense.dart';
import 'package:solaina/services/expense_service.dart';

void main() {
  group('ExpenseService.calculateBalances', () {
    const members = ['alice', 'bob', 'carol', 'dave'];

    test('one person pays, split evenly among all four', () {
      final expenses = [
        Expense(
          id: '1',
          description: 'Groceries',
          amount: 100,
          paidBy: 'alice',
          splitAmong: members,
          createdAt: DateTime.now(),
          settled: false,
        ),
      ];

      final balances = ExpenseService.calculateBalances(expenses, members);

      expect(balances['alice'], 75); // paid 100, owes 25 back
      expect(balances['bob'], -25);
      expect(balances['carol'], -25);
      expect(balances['dave'], -25);
    });

    test('settled expenses do not affect balances', () {
      final expenses = [
        Expense(
          id: '1',
          description: 'Rent',
          amount: 400,
          paidBy: 'bob',
          splitAmong: members,
          createdAt: DateTime.now(),
          settled: true,
        ),
      ];

      final balances = ExpenseService.calculateBalances(expenses, members);

      expect(balances.values.every((balance) => balance == 0), isTrue);
    });

    test('multiple expenses net out correctly', () {
      final expenses = [
        Expense(
          id: '1',
          description: 'Groceries',
          amount: 40,
          paidBy: 'alice',
          splitAmong: ['alice', 'bob'],
          createdAt: DateTime.now(),
          settled: false,
        ),
        Expense(
          id: '2',
          description: 'Utilities',
          amount: 40,
          paidBy: 'bob',
          splitAmong: ['alice', 'bob'],
          createdAt: DateTime.now(),
          settled: false,
        ),
      ];

      final balances = ExpenseService.calculateBalances(expenses, members);

      expect(balances['alice'], 0);
      expect(balances['bob'], 0);
      expect(balances['carol'], 0);
      expect(balances['dave'], 0);
    });
  });
}
